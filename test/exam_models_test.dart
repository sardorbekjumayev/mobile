import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/data/models/exam_models.dart';

void main() {
  group('ExamQuestion from POST /test/:id/start', () {
    test('drag_and_drop reads top-level items/targets and the resumed answer', () {
      final q = ExamQuestion.fromJson({
        'id': 'q1',
        'position': 1,
        'type': 'drag_and_drop',
        'text': 'Moslang',
        'items': ['Suv', 'Tuz'],
        'targets': ['H2O', 'NaCl'],
        'drag_answer': [1, 0],
      });

      expect(q.isDragAndDrop, isTrue);
      expect(q.dragItems?.items, ['Suv', 'Tuz']);
      expect(q.dragItems?.targets, ['H2O', 'NaCl']);
      expect(q.givenDrag, [1, 0]);
    });

    test('nested drag_items still parses', () {
      final q = ExamQuestion.fromJson({
        'id': 'q2',
        'position': 2,
        'type': 'drag_and_drop',
        'text': 'Moslang',
        'drag_items': {
          'items': ['a'],
          'targets': ['b'],
        },
      });

      expect(q.dragItems?.items, ['a']);
    });

    test('resumed single and multiple answers are kept', () {
      final single = ExamQuestion.fromJson({
        'id': 'q3',
        'position': 3,
        'text': 't',
        'options': ['a', 'b'],
        'chosen_index': 1,
      });
      final multi = ExamQuestion.fromJson({
        'id': 'q4',
        'position': 4,
        'type': 'multiple_choice',
        'text': 't',
        'options': ['a', 'b', 'c'],
        'chosen_indexes': [0, 2],
      });

      expect(single.givenIndex, 1);
      expect(multi.givenIndexes, [0, 2]);
      expect(single.dragItems, isNull);
    });
  });
}
