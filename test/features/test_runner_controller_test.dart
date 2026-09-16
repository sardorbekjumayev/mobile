import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/data/repositories/student_repository.dart';
import 'package:stepix/features/student/test_runner_controller.dart';

import '../fake_api_client.dart';

/// The sit-a-test sequence without a widget tree: what is sent, what is kept
/// when a packet is lost, and how a submit ends.
void main() {
  Map<String, dynamic> attempt({
    List<Map<String, dynamic>>? questions,
    bool solutionRequired = false,
    String? expiresAt,
  }) =>
      {
        'student_test_id': 'st1',
        'solution_required': solutionRequired,
        'solution_pages': 2,
        'expires_at': ?expiresAt,
        'time_limit_min': 30,
        'questions': questions ??
            [
              {'id': 'q1', 'position': 1, 'text': 'A?', 'options': ['a', 'b']},
              {'id': 'q2', 'position': 2, 'type': 'multiple_choice', 'text': 'B?', 'options': ['a', 'b', 'c']},
              {
                'id': 'q3',
                'position': 3,
                'type': 'drag_and_drop',
                'text': 'C?',
                'items': ['x', 'y'],
                'targets': ['1', '2'],
              },
            ],
      };

  TestRunnerController build(FakeApiClient api) =>
      TestRunnerController(repository: StudentRepository(api), testId: 't1');

  test('start loads the attempt and opens on the first question', () async {
    final api = FakeApiClient({'POST /test/t1/start': attempt()});
    final c = build(api);
    await c.start();
    expect(c.phase, RunnerPhase.running);
    expect(c.total, 3);
    expect(c.isFirst, isTrue);
    expect(c.current!.id, 'q1');
    expect(c.hasAnswered, isFalse);
    c.dispose();
  });

  test('a start the server refuses is a failed phase with its message', () async {
    final api = FakeApiClient({'POST /test/t1/start': ApiException(message: 'Urinishlar tugadi', code: 20803)});
    final c = build(api);
    await c.start();
    expect(c.phase, RunnerPhase.failed);
    expect(c.error, 'Urinishlar tugadi');
    c.dispose();
  });

  test('a resumed attempt restores every type of given answer', () async {
    final api = FakeApiClient({
      'POST /test/t1/start': attempt(questions: [
        {'id': 'q1', 'position': 1, 'options': ['a', 'b'], 'chosen_index': 1},
        {'id': 'q2', 'position': 2, 'type': 'multiple_choice', 'options': ['a', 'b'], 'chosen_indexes': [0, 1]},
        {
          'id': 'q3',
          'position': 3,
          'type': 'drag_and_drop',
          'items': ['x', 'y'],
          'targets': ['1', '2'],
          'drag_answer': [1, -1],
        },
      ]),
    });
    final c = build(api);
    await c.start();
    expect(c.chosenIndex, 1);
    c.next();
    expect(c.chosenIndexes, {0, 1});
    c.next();
    expect(c.dragTargets, [1, null]);
    expect(c.hasAnswered, isFalse);
    expect(c.unansweredCount, 1);
    c.dispose();
  });

  test('each question type pushes its own answer shape', () async {
    final api = FakeApiClient({'POST /test/t1/start': attempt(), 'POST /test/t1/answer': {'saved': true}});
    final c = build(api);
    await c.start();

    await c.chooseSingle(1);
    expect((api.bodies['POST /test/t1/answer']! as Map)['chosen_index'], 1);
    expect(c.hasAnswered, isTrue);

    c.next();
    await c.toggleMultiple(0);
    await c.toggleMultiple(2);
    await c.toggleMultiple(0);
    expect(c.chosenIndexes, {2});
    expect((api.bodies['POST /test/t1/answer']! as Map)['chosen_indexes'], [2]);

    c.next();
    api.calls.clear();
    await c.setDragTarget(0, 1);
    // A partial mapping is not a valid drag_answer and is never sent.
    expect(api.calls, isEmpty);
    await c.setDragTarget(1, 0);
    expect((api.bodies['POST /test/t1/answer']! as Map)['drag_answer'], [1, 0]);
    expect(c.isLast, isTrue);
    expect(c.unansweredCount, 0);
    c.dispose();
  });

  test('navigation stays within the paper', () async {
    final api = FakeApiClient({'POST /test/t1/start': attempt()});
    final c = build(api);
    await c.start();
    c.previous();
    expect(c.index, 0);
    c.jumpTo(2);
    expect(c.index, 2);
    c.next();
    expect(c.index, 2);
    c.jumpTo(9);
    expect(c.index, 2);
    expect(c.progress, 1);
    c.dispose();
  });

  test('a lost answer is kept on screen and resent before submit', () async {
    final api = FakeApiClient({
      'POST /test/t1/start': attempt(),
      'POST /test/t1/answer': ApiException.network('offline'),
      'POST /test/t1/submit': {'score': 33},
    });
    final c = build(api);
    await c.start();
    await c.chooseSingle(0);
    expect(c.chosenIndex, 0);
    expect(c.hasUnsynced, isTrue);

    api.responses['POST /test/t1/answer'] = {'saved': true};
    api.calls.clear();
    expect(await c.submit(), isTrue);
    expect(api.calls, ['POST /test/t1/answer', 'POST /test/t1/submit']);
    expect(c.hasUnsynced, isFalse);
    expect(c.phase, RunnerPhase.submitted);
    expect(c.outcome?.score, 33);
    c.dispose();
  });

  test('a second submit (20802) is accepted as the one that stands', () async {
    final api = FakeApiClient({
      'POST /test/t1/start': attempt(),
      'POST /test/t1/submit': ApiException(message: 'Already', code: ErrorCodes.testAlreadySubmitted),
    });
    final c = build(api);
    await c.start();
    expect(await c.submit(), isTrue);
    expect(c.phase, RunnerPhase.submitted);
    c.dispose();
  });

  test('20811 asks for the solution sheet, and once uploaded it is not asked again', () async {
    final api = FakeApiClient({
      'POST /test/t1/start': attempt(),
      'POST /test/t1/submit': ApiException(message: 'Varaq kerak', code: ErrorCodes.solutionRequired),
    });
    final c = build(api);
    await c.start();
    expect(c.needsSolution, isFalse);

    expect(await c.submit(), isFalse);
    expect(c.phase, RunnerPhase.running);
    expect(c.error, 'Varaq kerak');
    expect(c.needsSolution, isTrue);

    c.markSolutionUploaded();
    expect(c.needsSolution, isFalse);
    c.dispose();
  });

  test('a test that requires a sheet says so from the start payload', () async {
    final api = FakeApiClient({'POST /test/t1/start': attempt(solutionRequired: true)});
    final c = build(api);
    await c.start();
    expect(c.needsSolution, isTrue);
    expect(c.solutionPages, 2);
    c.dispose();
  });

  test('any other submit failure returns to the paper with the message', () async {
    final api = FakeApiClient({
      'POST /test/t1/start': attempt(),
      'POST /test/t1/submit': ApiException(message: 'Server', code: 10000),
    });
    final c = build(api);
    await c.start();
    expect(await c.submit(), isFalse);
    expect(c.phase, RunnerPhase.running);
    expect(c.error, 'Server');
    c.dispose();
  });

  test('the countdown reaching zero hands over to onTimeUp', () async {
    final api = FakeApiClient({
      'POST /test/t1/start': attempt(
        expiresAt: DateTime.now().subtract(const Duration(seconds: 5)).toUtc().toIso8601String(),
      ),
    });
    final c = build(api);
    var fired = 0;
    c.onTimeUp = () async => fired++;
    await c.start();
    expect(c.remaining, Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(fired, 1);
    c.dispose();
  });
}
