import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';
import '../widget_harness.dart';

/// The student's half of the app, screen by screen, against the fake API.
void main() {
  usePhoneView();

  Map<String, dynamic> question(int position, {int? chosen}) => {
        'id': 'q$position',
        'position': position,
        'text': 'Savol $position',
        'options': const ['go', 'goes', 'going'],
        'chosen_index': chosen,
      };

  testWidgets('home shows the next test, a pending sheet, advice and the groups', (tester) async {
    final api = FakeApiClient({
      ...studentStubs(),
      'GET /home': {
        'greeting': 'morning',
        'streak_days': 5,
        'avg_score': 78,
        'avg_score_delta': 4,
        'rank': 3,
        'advice': 'Kvadrat tenglamalarni takrorlang.',
        'metrics': [
          {'key': 'tests_taken', 'value': 12},
        ],
        'week': [],
        'next_test': {'id': 't1', 'title': 'Unit 4', 'question_count': 20, 'time_limit_min': 25},
        'pending_solutions': [
          {'test_id': 't9', 'title': 'Algebra', 'solution_pages': 2, 'retry': false},
        ],
      },
      'GET /group': [
        {'id': 'g1', 'name': 'IELTS Evening', 'my_avg_score': 81, 'teacher': {'full_name': 'Kamola'}},
      ],
      'GET /test/t1': {'id': 't1', 'title': 'Unit 4', 'attempts_left': 1, 'state': 'assigned'},
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);

    expect(find.text('Xayrli tong'), findsOneWidget);
    expect(find.text('5 kun'), findsOneWidget);
    expect(find.text('Unit 4'), findsOneWidget);
    expect(find.text('Ishlangan varaqni yuklang'), findsOneWidget);
    expect(find.text('Algebra'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Kvadrat tenglamalarni takrorlang.'), 200);
    expect(find.text('AI tavsiyasi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('IELTS Evening'), 200);
    expect(find.text('Mashq testi yaratish'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Boshlash'), -200);
    await tester.tap(find.text('Boshlash'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('GET /test/t1'));
  });

  testWidgets('the tests tab splits pending from done', (tester) async {
    final api = FakeApiClient({
      ...studentStubs(),
      'GET /test': (Object? q) => switch ((q! as Map)['state']) {
            'in_progress' => {
                'total': 1,
                'data': [
                  {'id': 'a', 'title': 'Boshlangan', 'state': 'in_progress', 'group_name': 'G'},
                ],
              },
            'assigned' => {
                'total': 1,
                'data': [
                  {'id': 'b', 'title': 'Yangi', 'state': 'assigned', 'group_name': 'G'},
                ],
              },
            _ => {
                'total': 1,
                'data': [
                  {'id': 'c', 'title': 'Tugagan', 'state': 'submitted', 'score': 91, 'group_name': 'G'},
                ],
              },
          },
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await tester.tap(find.text('Testlar'));
    await tester.pumpAndSettle();

    // Started first: the test the student came back for.
    final started = tester.getTopLeft(find.text('Boshlangan')).dy;
    final fresh = tester.getTopLeft(find.text('Yangi')).dy;
    expect(started, lessThan(fresh));
    expect(find.text('Davom ettirish'), findsOneWidget);
    expect(find.text('Topshirish'), findsOneWidget);

    await tester.tap(find.text('Topshirilgan'));
    await tester.pumpAndSettle();
    expect(find.text('Tugagan'), findsOneWidget);
    expect(find.text('91'), findsOneWidget);
    expect(find.text('Yangi'), findsNothing);
  });

  group('test cover', () {
    Future<void> openCover(WidgetTester tester, Map<String, dynamic> test) async {
      await pumpApp(
        tester,
        api: FakeApiClient({...studentStubs(), 'GET /test/t1': test}),
        tokens: signedInTokens,
      );
      await goTo(tester, '/student/test/t1');
    }

    testWidgets('an in-progress test offers to continue, with the sheet requirement', (tester) async {
      await openCover(tester, {
        'id': 't1',
        'title': 'Unit 4',
        'state': 'in_progress',
        'attempts_left': 1,
        'question_count': 20,
        'time_limit_min': 30,
        'solution_required': true,
        'solution_pages': 2,
      });
      expect(find.text('Davom ettirish'), findsOneWidget);
      expect(find.text('Ishlangan varaq talab qilinadi'), findsOneWidget);
      expect(find.text('30 daqiqa'), findsOneWidget);
    });

    testWidgets('a submitted test leads to its result', (tester) async {
      await openCover(tester, {'id': 't1', 'title': 'U', 'state': 'submitted', 'attempts_left': 1});
      expect(find.text('Natija'), findsOneWidget);
      expect(find.text('Boshlash'), findsNothing);
    });

    testWidgets('no attempts left is said, not a dead button', (tester) async {
      await openCover(tester, {'id': 't1', 'title': 'U', 'state': 'assigned', 'attempts_left': 0});
      expect(find.text('Urinishlar tugadi'), findsOneWidget);
    });
  });

  testWidgets('the runner sends answers, warns about gaps and lands on the result', (tester) async {
    // The failed-score hero ("50 O'ta olmadingiz") overflows at 390px.
    useWideView(tester);
    final api = FakeApiClient({
      ...studentStubs(),
      'POST /test/t1/start': {
        'student_test_id': 'st1',
        'questions': [question(1), question(2)],
      },
      'POST /test/t1/answer': {'saved': true},
      'POST /test/t1/submit': {'score': 50, 'passed': false},
      'GET /test/t1/result': {
        'title': 'Unit 4',
        'score': 50,
        'correct_count': 1,
        'total': 2,
        'passed': false,
        'questions': [],
      },
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/student/test/t1/run');

    expect(find.text('Savol 1'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.text('goes'));
    await tester.pumpAndSettle();
    expect(api.bodies['POST /test/t1/answer'], {
      'student_test_id': 'st1',
      'question_id': 'q1',
      'chosen_index': 1,
      'time_spent_ms': isA<int>(),
    });

    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle();
    expect(find.text('Savol 2'), findsOneWidget);
    expect(find.text('Oldingi'), findsOneWidget);

    await tester.tap(find.text('Yakunlash'));
    await tester.pumpAndSettle();
    expect(find.text('Hamma savolga javob berilmagan'), findsOneWidget);
    expect(find.textContaining('1 ta savol'), findsOneWidget);

    await tester.tap(find.text('Baribir yakunlash'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('POST /test/t1/submit'));
    expect(find.text('O\'ta olmadingiz'), findsOneWidget);
  });

  testWidgets('leaving the runner asks first and keeps the attempt', (tester) async {
    final api = FakeApiClient({
      ...studentStubs(),
      'POST /test/t1/start': {'student_test_id': 'st1', 'questions': [question(1)]},
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/student/test/t1/run');

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Testdan chiqilsinmi?'), findsOneWidget);
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    expect(find.text('Savol 1'), findsOneWidget);
    expect(api.calls, isNot(contains('POST /test/t1/submit')));
  });

  group('result', () {
    testWidgets('a hidden review says so and a failed sheet asks for a re-upload', (tester) async {
      // The analysis title row overflows at 390px with the "failed" chip.
      useWideView(tester);
      await pumpApp(
        tester,
        tokens: signedInTokens,
        api: FakeApiClient({
          ...studentStubs(),
          'GET /test/t1/result': {
            'title': 'Unit 4',
            'score': 88,
            'correct_count': 22,
            'total': 25,
            'passed': true,
            'solution_required': true,
            'solution_pages': 2,
            'solution': {'state': 'failed', 'pages': 2, 'error': 'Rasm xira'},
            'questions': [
              {'id': 'q', 'position': 1, 'text': 'T', 'options': ['a']},
            ],
          },
        }),
      );
      await goTo(tester, '/student/test/t1/result');

      expect(find.text('88'), findsOneWidget);
      expect(find.text('O\'tdingiz'), findsOneWidget);
      expect(find.text('22/25 to\'g\'ri javob'), findsOneWidget);
      expect(find.text('Rasm xira'), findsOneWidget);
      expect(find.text('Varaq o\'qilmadi — qayta yuklang'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Markaz javoblarni ko\'rsatishni o\'chirgan.'), 200);
    });

    testWidgets('an open review marks the right and the wrong choice, with the explanation', (tester) async {
      await pumpApp(
        tester,
        tokens: signedInTokens,
        api: FakeApiClient({
          ...studentStubs(),
          'GET /test/t1/result': {
            'title': 'Unit 4',
            'score': 0,
            'total': 1,
            'questions': [
              {
                'id': 'q',
                'position': 1,
                'text': 'She ___',
                'options': ['go', 'goes'],
                'answer_index': 1,
                'chosen_index': 0,
                'explanation': 'Uchinchi shaxs -s oladi.',
              },
            ],
          },
        }),
      );
      await goTo(tester, '/student/test/t1/result');

      expect(find.text('She ___'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.text('Uchinchi shaxs -s oladi.'), findsOneWidget);
    });
  });

  testWidgets('the rating says how to get ranked, and lists the leaders', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...studentStubs(),
        'GET /leaderboard': {
          'my_rank': null,
          'total_ranked': 26,
          'leaders': [
            {'rank': 1, 'full_name': 'Zarina Ergasheva', 'score': 95, 'tests': 9},
            {'rank': 2, 'full_name': 'Ali Valiyev', 'score': 90, 'tests': 8, 'is_me': true},
          ],
        },
        'GET /badge': [
          {'code': 'top3', 'earned': false},
        ],
      }),
    );
    await tester.tap(find.text('Reyting').last);
    await tester.pumpAndSettle();

    expect(find.text('Reytingda emassiz'), findsOneWidget);
    expect(find.text('Reytingga kirish uchun kamida 3 ta test topshiring.'), findsOneWidget);
    expect(find.text('Zarina Ergasheva'), findsOneWidget);
    expect(find.text('ZE'), findsOneWidget);
    // The home tab's list is kept alive under this one, so drag the rating's own.
    await tester.drag(find.text('Zarina Ergasheva'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Markaz top-3'), findsOneWidget);
  });

  testWidgets('a practice paper is built from a topic and polled until ready', (tester) async {
    final api = FakeApiClient({
      ...studentStubs(),
      'GET /practice/subjects': [
        {'id': 's1', 'name': 'Matematika'},
      ],
      'GET /practice/quota': {'unlimited': true, 'remaining': 9999, 'limit': 9999},
      'GET /practice/program': {
        'subject': {'id': 's1', 'name': 'Matematika'},
        'branches': [
          {
            'id': 'b1',
            'name': 'Algebra',
            'topics': [
              {'id': 'tp1', 'name': 'Kvadrat tenglama', 'position': 1},
            ],
          },
        ],
      },
      'POST /practice/generate': {'job_id': 'j1', 'test_id': 'tx'},
      'GET /practice/generate/j1': {'state': 'ready', 'test_id': 'tx', 'title': 'Kvadrat tenglama · mashq'},
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/student/practice');

    // One subject is chosen for the student; its program is already loaded.
    expect(api.bodies['GET /practice/program'], {'subject_id': 's1'});
    expect(find.text('Testni yaratish'), findsOneWidget);

    await tester.tap(find.text('Mavzu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kvadrat tenglama'));
    await tester.pumpAndSettle();
    expect(find.text('Algebra · Kvadrat tenglama'), findsOneWidget);

    await tester.tap(find.text('Qiyin'));
    await tester.tap(find.text('Testni yaratish'));
    // Plain pumps: settling would run the fake clock past the 2s poll.
    await tester.pump();
    await tester.pump();
    expect(api.bodies['POST /practice/generate'], {
      'topic_id': 'tp1',
      'question_count': 10,
      'difficulty': 'hard',
    });
    expect(find.text('Test tayyorlanmoqda'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    expect(find.text('Test tayyor'), findsOneWidget);
    expect(find.text('Kvadrat tenglama · mashq'), findsOneWidget);
  });

  testWidgets('the student solution upload shows the retry notice and waits for a photo', (tester) async {
    final api = FakeApiClient(studentStubs());
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/student/test/t1/solution?pages=2&retry=1');

    expect(find.text('Ishlangan varag\'ingizni yuklang'), findsOneWidget);
    expect(find.textContaining('Oldingi varaqni o\'qib bo\'lmadi'), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galereya'), findsOneWidget);

    // No photo yet: the upload button does nothing.
    await tester.tap(find.text('Yuklash'));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.contains('/solution')), isEmpty);
  });

  testWidgets('a group page shows the teacher, the schedule and classmates', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...studentStubs(),
        'GET /group/g1': {
          'id': 'g1',
          'name': 'IELTS Evening',
          'subject': 'Ingliz tili',
          'room': '204',
          'schedule': [
            {'day': 1, 'start': '18:00', 'end': '19:30'},
          ],
          'teacher': {'full_name': 'Kamola Tashpulatova'},
          'classmates': [
            {'full_name': 'Sardor Nazarov'},
          ],
          'tests': [
            {'id': 't1', 'title': 'Mock 1', 'state': 'submitted', 'score': 70, 'group_name': 'IELTS'},
          ],
        },
      }),
    );
    await goTo(tester, '/student/group/g1');

    expect(find.text('Kamola Tashpulatova'), findsOneWidget);
    expect(find.text('Du 18:00–19:30'), findsOneWidget);
    expect(find.text('Guruhdoshlar · 1'), findsOneWidget);
    expect(find.text('SN'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mock 1'), 200);
  });
}
