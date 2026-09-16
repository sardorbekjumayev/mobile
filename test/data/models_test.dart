import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/data/models/exam_models.dart';
import 'package:stepix/data/models/knowledge_models.dart';
import 'package:stepix/data/models/profile_models.dart';
import 'package:stepix/data/models/rank_models.dart';
import 'package:stepix/data/models/session_models.dart';
import 'package:stepix/data/models/solution_models.dart';
import 'package:stepix/data/models/student_models.dart';
import 'package:stepix/data/models/teacher_models.dart';

/// The readers every screen stands on. Each group feeds one model the shapes the
/// API actually sends — and the ones it sends when a field is missing or odd.
void main() {
  group('session', () {
    test('an unknown role reads as a student, never as a teacher', () {
      expect(UserRole.parse('teacher'), UserRole.teacher);
      expect(UserRole.parse('center_admin'), UserRole.student);
      expect(UserRole.parse(null), UserRole.student);
    });

    test('a user with missing fields still has a language and initials', () {
      final u = AppUser.fromJson({'id': 'u1', 'full_name': '  ali   valiyev '});
      expect(u.language, 'uz');
      expect(u.firstName, 'ali');
      expect(u.initials, 'AV');
      expect(u.mustChangePassword, isFalse);
      expect(u.copyWith(language: 'ru').language, 'ru');
      expect(u.copyWith(language: 'ru').fullName, u.fullName);
    });

    test('initials cope with one word and with nothing', () {
      expect(initialsOf('Ali'), 'A');
      expect(initialsOf(''), '');
      expect(initialsOf('   '), '');
    });

    test('brand colours accept #rgb, #rrggbb and #aarrggbb and refuse garbage', () {
      expect(parseHexColor('#1f63d6'), const Color(0xff1f63d6));
      expect(parseHexColor('abc'), const Color(0xffaabbcc));
      expect(parseHexColor('80112233'), const Color(0x80112233));
      expect(parseHexColor('#12'), isNull);
      expect(parseHexColor('#zzzzzz'), isNull);
      expect(parseHexColor(null), isNull);
    });

    test('identity reads the center, and no center at all', () {
      final withCenter = Identity.fromJson({
        'user': {'id': 'u1', 'role': 'teacher'},
        'center': {'id': 'c1', 'name': 'X', 'brand_primary': '#000000'},
      });
      expect(withCenter.user.role.isTeacher, isTrue);
      expect(withCenter.center?.brandPrimary, const Color(0xff000000));
      expect(Identity.fromJson({'user': {'id': 'u1'}}).center, isNull);
    });

    test('a lookup without a role keeps the role null', () {
      expect(PhoneLookup.fromJson({'found': true}).role, isNull);
      expect(PhoneLookup.fromJson({'found': true, 'role': 'teacher'}).role, UserRole.teacher);
      expect(const PhoneLookup.notFound().found, isFalse);
    });
  });

  group('profile', () {
    test('the profile reads a nested user or a flat one', () {
      final nested = UserProfile.fromJson({
        'user': {'id': 'u1', 'full_name': 'Ali'},
        'center': {'name': 'C'},
        'avg_score': null,
      });
      final flat = UserProfile.fromJson({'id': 'u2', 'full_name': 'Vali', 'center_name': 'D'});
      expect(nested.user.fullName, 'Ali');
      expect(nested.centerName, 'C');
      expect(nested.avgScore, isNull);
      expect(flat.user.id, 'u2');
      expect(flat.centerName, 'D');
    });

    test('settings stats are absent on an older server and empty when all zero', () {
      expect(AppSettings.fromJson({'force_update': 1}).forceUpdate, isTrue);
      expect(AppSettings.fromJson({}).stats, isNull);
      expect(
        AppSettings.fromJson({'stats': {'students': 0, 'tests': 0, 'centers': 0}}).stats!.isEmpty,
        isTrue,
      );
    });

    test('a past-due subscription is in grace only until grace_until', () {
      final future = DateTime.now().add(const Duration(days: 2)).toIso8601String();
      final past = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      expect(Subscription.fromJson({'status': 'past_due', 'grace_until': future}).inGrace, isTrue);
      expect(Subscription.fromJson({'status': 'past_due', 'grace_until': past}).inGrace, isFalse);
      expect(Subscription.fromJson({'status': 'active'}).isActive, isTrue);
      expect(Subscription.fromJson({}).status, 'none');
    });

    test('the notification feed survives a missing data array', () {
      final feed = NotificationFeed.fromJson({'total': 3});
      expect(feed.items, isEmpty);
      final n = AppNotification.fromJson({'id': 'n', 'ref_id': '', 'is_read': 'true'});
      expect(n.refId, isNull);
      expect(n.isRead, isTrue);
    });
  });

  group('rank', () {
    test('an unranked student has no rank, and rank 0 is unranked too', () {
      expect(Leaderboard.fromJson({}).isRanked, isFalse);
      expect(Leaderboard.fromJson({'my_rank': 0}).isRanked, isFalse);
      expect(Leaderboard.fromJson({'my_rank': 4}).isRanked, isTrue);
    });

    test('a leader without initials gets them from the name', () {
      final row = LeaderRow.fromJson({'full_name': 'Madina Saidova', 'rank': '2'});
      expect(row.initials, 'MS');
      expect(row.rank, 2);
    });

    test('badge progress is clamped and a zero target is not a division by zero', () {
      expect(const BadgeProgress(current: 30, target: 20).fraction, 1);
      expect(const BadgeProgress(current: 5, target: 0).fraction, 0);
      expect(Badge.fromJson({'code': 'x'}).progress, isNull);
    });
  });

  group('solution', () {
    test('an unknown state is null — "not uploaded" — not waiting', () {
      expect(SolutionState.parse('bogus'), isNull);
      expect(SolutionState.waiting.isPending, isTrue);
      expect(SolutionState.done.isPending, isFalse);
    });

    test('a failed or missing sheet needs an upload; a waiting one does not', () {
      expect(Solution.needsUpload(null), isTrue);
      expect(Solution.needsUpload(Solution.fromJson({'state': 'failed'})), isTrue);
      expect(Solution.needsUpload(Solution.fromJson({'state': 'waiting'})), isFalse);
      expect(Solution.maybe('nope'), isNull);
    });

    test('the analysis sorts questions, clamps legibility and counts errors', () {
      final r = SolutionResult.fromJson({
        'legibility': 1.7,
        'error_counts': {'calculation': '2', 'formula': 1},
        'questions': [
          {'n': 3, 'is_correct': 'yes'},
          {'n': 1, 'is_correct': true},
        ],
      });
      expect(r.legibility, 1.0);
      expect(r.errorCounts, {'calculation': 2, 'formula': 1});
      expect(r.questions.map((q) => q.n), [1, 3]);
      expect(r.questions.last.isCorrect, isNull);
      expect(r.questions.first.work, 'none');
      expect(r.questions.first.errorType, SolutionErrorType.none);
      expect(SolutionResult.fromJson({'legibility': 'x'}).legibility, isNull);
    });

    test('solution status defaults to one page', () {
      expect(SolutionStatus.fromJson({}).pages, 1);
      expect(PendingSolution.fromJson({'retry': 1}).retry, isTrue);
    });
  });

  group('knowledge', () {
    test('a source reads its result block and ignores empty topic labels', () {
      final s = KnowledgeSource.fromJson({
        'id': 'k1',
        'state': 'analyzing',
        'result': {
          'subject': 'Algebra',
          'questions': 12,
          'topics': [
            {'label': 'Kvadrat'},
            {'label': ''},
          ],
        },
      });
      expect(s.kind, 'test');
      expect(s.inProgress, isTrue);
      expect(s.subject, 'Algebra');
      expect(s.topics, ['Kvadrat']);
      expect(KnowledgeSource.fromJson({'state': 'weird'}).state, KnowledgeState.queued);
      expect(KnowledgeSource.fromJson({'state': 'done'}).inProgress, isFalse);
    });

    test('a detail carries the example question of each item', () {
      final d = KnowledgeSourceDetail.fromJson({
        'id': 'k1',
        'knowledge': [
          {
            'kind': 'misconception',
            'topic_label': 'T',
            'example': {'text': 'Q', 'options': ['a', 'b'], 'depth': 4, 'student_error': 'E'},
          },
        ],
      });
      final item = d.items.single;
      expect(item.questionText, 'Q');
      expect(item.options, ['a', 'b']);
      expect(item.depth, 4);
      expect(item.studentError, 'E');
      expect(d.source.id, 'k1');
    });
  });

  group('student', () {
    test('a test summary reads group_name or a nested group', () {
      expect(TestSummary.fromJson({'group_name': 'A'}).groupName, 'A');
      expect(TestSummary.fromJson({'group': {'name': 'B'}}).groupName, 'B');
    });

    test('a test can be started only with attempts left and not submitted', () {
      expect(TestSummary.fromJson({'attempts_left': 1, 'state': 'assigned'}).canStart, isTrue);
      expect(TestSummary.fromJson({'attempts_left': 0}).canStart, isFalse);
      expect(TestSummary.fromJson({'attempts_left': 2, 'state': 'submitted'}).canStart, isFalse);
    });

    test('test state wire values round-trip and unknown ones read as assigned', () {
      for (final s in TestState.values) {
        expect(TestState.parse(s.wire), s);
      }
      expect(TestState.parse('new'), TestState.assigned);
    });

    test('home reads metrics by key, pending sheets and the no-group state', () {
      final h = StudentHome.fromJson({
        'metrics': [
          {'key': 'tests_taken', 'value': 12},
        ],
        'empty_state': 'no_group',
        'pending_solutions': [
          {'test_id': 't', 'solution_pages': 2},
        ],
        'next_test': null,
      });
      expect(h.greeting, 'morning');
      expect(h.metric('tests_taken'), 12);
      expect(h.metric('missing'), 0);
      expect(h.hasNoGroup, isTrue);
      expect(h.nextTest, isNull);
      expect(h.pendingSolutions.single.pages, 2);
    });

    test('skill tone is the server bucket, defaulting to ok', () {
      expect(SkillTone.parse('weak'), SkillTone.weak);
      expect(SkillTone.parse(null), SkillTone.ok);
      expect(StudentProgress.fromJson({}).isEmpty, isTrue);
    });

    test('a group detail reads a nested group or a flat one, and classmate initials', () {
      final nested = StudentGroupDetail.fromJson({
        'group': {'id': 'g1', 'name': 'G', 'teacher': {'full_name': 'T'}},
        'classmates': [
          {'full_name': 'Madina Saidova'},
        ],
      });
      final flat = StudentGroupDetail.fromJson({'id': 'g2', 'name': 'H'});
      expect(nested.group.teacher?.fullName, 'T');
      expect(nested.classmates.single.initials, 'MS');
      expect(flat.group.id, 'g2');
      expect(flat.group.teacher, isNull);
    });
  });

  group('exam', () {
    test('an unknown question type is single choice', () {
      expect(questionTypeOf('essay'), QuestionKind.singleChoice);
      expect(questionTypeOf(null), QuestionKind.singleChoice);
      expect(questionTypeOf('image_based'), QuestionKind.imageBased);
    });

    test('an attempt sorts questions and caps remaining time at the limit', () {
      final a = TestAttempt.fromJson({
        'student_test_id': 'st',
        'questions': [
          {'id': 'b', 'position': 2},
          {'id': 'a', 'position': 1},
        ],
        'expires_at': DateTime.now().add(const Duration(hours: 10)).toUtc().toIso8601String(),
        'time_limit_min': 30,
      });
      expect(a.questions.map((q) => q.id), ['a', 'b']);
      expect(a.attemptNo, 1);
      expect(a.remaining, const Duration(minutes: 30));
    });

    test('an expired attempt has zero time left and no expiry has no countdown', () {
      final expired = TestAttempt.fromJson({
        'expires_at': DateTime.now().subtract(const Duration(minutes: 1)).toUtc().toIso8601String(),
      });
      expect(expired.remaining, Duration.zero);
      expect(TestAttempt.fromJson({}).remaining, isNull);
    });

    test('a figure skips malformed rows and reads dashed edges', () {
      final f = QuestionFigure.fromJson({
        'lines': [
          [0, 0, 10, 10, 1],
          'junk',
          [],
        ],
        'circles': [
          [5, 5],
        ],
        'labels': [
          [1, 2, 'A'],
          ['x'],
        ],
      });
      expect(f.lines.single.dashed, isTrue);
      expect(f.circles.single.r, 0);
      expect(f.labels.first.text, 'A');
      expect(f.labels.last.x, 0);
      expect(QuestionFigure.fromJson({}).isEmpty, isTrue);
    });

    test('media is present only with a non-empty url', () {
      expect(ExamQuestion.fromJson({'media_url': 'http://x'}).hasMedia, isTrue);
      expect(ExamQuestion.fromJson({'media_url': ''}).hasMedia, isFalse);
    });

    test('result correctness follows the server verdict first, then each type', () {
      expect(ResultQuestion.fromJson({'is_correct': false, 'answer_index': 1, 'chosen_index': 1}).isCorrect,
          isFalse);
      expect(ResultQuestion.fromJson({'answer_index': 1, 'chosen_index': 1}).isCorrect, isTrue);
      expect(ResultQuestion.fromJson({'answer_index': 1}).isCorrect, isFalse);
      expect(ResultQuestion.fromJson({'answer_index': 1}).isUnanswered, isTrue);

      final multi = ResultQuestion.fromJson({
        'type': 'multiple_choice',
        'answer_indexes': [0, 2],
        'chosen_indexes': [2, 0],
      });
      expect(multi.isCorrect, isTrue);
      expect(
        ResultQuestion.fromJson({
          'type': 'multiple_choice',
          'answer_indexes': [0, 2],
          'chosen_indexes': [0],
        }).isCorrect,
        isFalse,
      );

      final drag = ResultQuestion.fromJson({
        'type': 'drag_and_drop',
        'items': ['a', 'b'],
        'targets': ['x', 'y'],
        'correct': [1, 0],
        'drag_answer': [1, 0],
      });
      expect(drag.isCorrect, isTrue);
      expect(drag.hasAnswerKey, isTrue);
    });

    test('answers are hidden when no question carries its key', () {
      final hidden = TestResult.fromJson({
        'questions': [
          {'id': 'q', 'options': ['a']},
        ],
      });
      final shown = TestResult.fromJson({
        'test_id': 't9',
        'question_count': 5,
        'questions': [
          {'id': 'q', 'answer_index': 0},
        ],
      });
      expect(hidden.answersHidden, isTrue);
      expect(shown.answersHidden, isFalse);
      expect(shown.testId, 't9');
      expect(shown.total, 5);
    });

    test('an answer ack defaults to saved, a submit outcome reads new badges', () {
      expect(AnswerAck.fromJson({}).saved, isTrue);
      expect(SubmitOutcome.fromJson({'new_badges': ['top3']}).newBadges, ['top3']);
    });
  });

  group('teacher', () {
    test('the program reads the chosen subject and every subject taught', () {
      final p = TeacherProgram.fromJson({
        'subject': {'id': 's2', 'name': 'Fizika'},
        'subjects': [
          {'id': 's1', 'name': 'Matematika'},
          {'id': 's2', 'name': 'Fizika'},
        ],
        'branches': [
          {
            'id': 'b1',
            'name': 'Mexanika',
            'topics': [
              {'id': 't1', 'name': 'Kuch', 'is_custom': true, 'from_material': true},
            ],
          },
        ],
      });
      expect(p.subjectId, 's2');
      expect(p.subjects.map((s) => s.name), ['Matematika', 'Fizika']);
      expect(p.branches.single.topics.single.fromMaterial, isTrue);
      expect(p.isEmpty, isFalse);
    });

    test('an older program payload has no subject list and topics not from material', () {
      final p = TeacherProgram.fromJson({
        'subject': {'name': 'Matematika'},
        'branches': [
          {'id': 'b1', 'topics': []},
        ],
      });
      expect(p.subjectId, '');
      expect(p.subjects, isEmpty);
      expect(p.isEmpty, isTrue);
      expect(ProgramTopic.fromJson({'id': 't'}).fromMaterial, isFalse);
    });

    test('a material upload reports reading, ready and failed', () {
      final reading = TeacherMaterial.fromJson({'id': 'm1', 'kind': 'pdf'});
      final ready = TeacherMaterial.fromJson({'id': 'm2', 'state': 'ready', 'chars': 1200});
      final failed = TeacherMaterial.fromJson({'id': 'm3', 'state': 'failed', 'error': '21404'});
      expect(reading.isReading, isTrue);
      expect(ready.isReady && !ready.isReading, isTrue);
      expect(ready.chars, 1200);
      expect(failed.isFailed, isTrue);
      expect(failed.error, '21404');
    });

    test('a group reads its subject id, and an old one leaves it empty', () {
      expect(TeacherGroup.fromJson({'subject_id': 's1'}).subjectId, 's1');
      final old = TeacherGroup.fromJson({'avg_score': null, 'attendance_pct': null});
      expect(old.subjectId, '');
      expect(old.avgScore, isNull);
      expect(old.attendancePct, isNull);
    });

    test('engagement is the server four words; anything else is new', () {
      expect(Engagement.parse('slipping').needsAttention, isTrue);
      expect(Engagement.parse('active').needsAttention, isFalse);
      expect(Engagement.parse('low'), Engagement.isNew);
    });

    test('attention items map their type and keep the raw one', () {
      final i = AttentionItem.fromJson({'type': 'low_score', 'group_id': 'g', 'avg_score': 48});
      expect(i.type, AttentionType.lowScore);
      expect(AttentionItem.fromJson({'type': 'future'}).type, AttentionType.other);
      expect(AttentionItem.fromJson({'type': 'future'}).raw, 'future');
    });

    test('a teacher test reads submitted/assigned under either name and computes progress', () {
      final t = TeacherTest.fromJson({'submitted': 3, 'assigned': 4, 'group': {'name': 'G'}});
      expect(t.progress, 0.75);
      expect(t.groupNames, ['G']);
      expect(t.isPublished, isFalse);
      expect(TeacherTest.fromJson({'submitted_count': 1, 'assigned_count': 0}).progress, 0);
      expect(
        TeacherTest.fromJson({
          'groups': [
            {'name': 'A'},
            'B',
            {'name': ''},
          ],
          'published_at': '2026-09-01T00:00:00Z',
        }).groupNames,
        ['A', 'B'],
      );
    });

    test('a group detail reads students or roster, and a student detail its nested student', () {
      final d = TeacherGroupDetail.fromJson({
        'group': {'id': 'g'},
        'roster': [
          {'student_id': 's1', 'full_name': 'A B'},
        ],
      });
      expect(d.roster.single.id, 's1');
      final s = StudentDetail.fromJson({'student': {'id': 'x', 'full_name': 'N', 'phone': '1'}, 'state': 'new'});
      expect(s.isNew, isTrue);
      expect(s.phone, '1');
    });

    test('participants carry their attempt id and sheet state', () {
      final p = TestParticipant.fromJson({
        'id': 'stu',
        'student_test_id': 'st1',
        'full_name': 'Ali Vali',
        'state': 'in_progress',
        'solution_state': 'done',
      });
      expect(p.studentId, 'stu');
      expect(p.state, TestState.inProgress);
      expect(p.solutionState, SolutionState.done);
    });

    test('attendance, difficulty and variant wire values', () {
      expect(AttendanceStatus.parse('late'), AttendanceStatus.late);
      expect(AttendanceStatus.parse('x'), AttendanceStatus.present);
      expect(
        const AttendanceMark(studentId: 's', status: AttendanceStatus.excused).toJson(),
        {'student_id': 's', 'status': 'excused'},
      );
      expect(TestDifficulty.hard.wire, 'hard');
      expect(TestVariantMode.unique.wire, 'unique');
    });

    test('quota is exhausted only when limited and at zero', () {
      expect(TeacherQuota.fromJson({'remaining': 0}).isExhausted, isTrue);
      expect(TeacherQuota.fromJson({'remaining': 0, 'unlimited': true}).isExhausted, isFalse);
    });

    test('flags serialise with the server defaults and copyWith changes one', () {
      final json = const TestFlags().copyWith(withImages: true).toJson();
      expect(json['with_images'], isTrue);
      expect(json['shuffle_questions'], isTrue);
      expect(json['allow_calculator'], isFalse);
    });

    test('a generation job is done at ready and failed at failed', () {
      final started = GenerationJob.started({'job_id': 'j', 'test_id': 't'});
      expect(started.state, 'queued');
      final polled = GenerationJob.polled({'state': 'ready', 'progress': '0.5'}, 'j');
      expect(polled.isDone, isTrue);
      expect(polled.progress, 0.5);
      expect(GenerationJob.polled({'state': 'failed'}, 'j').isFailed, isTrue);
    });

    test('review questions read per-type answers and a scan double mark is unanswered', () {
      final q = ReviewQuestion.fromJson({'chosen_index': -1, 'correct_index': 2});
      expect(q.wasAnswered, isFalse);
      expect(q.dragItems.isEmpty, isTrue);
      final sheet = StudentAnswerSheet.fromJson({
        'student': {'full_name': 'N'},
        'questions': [
          {'type': 'multiple_choice', 'chosen_indexes': [1], 'correct_indexes': [1, 2]},
        ],
      });
      expect(sheet.fullName, 'N');
      expect(sheet.questions.single.correctIndexes, [1, 2]);
    });

    test('letters stop at H', () {
      expect(letterOf(0), 'A');
      expect(letterOf(7), 'H');
      expect(letterOf(8), '?');
      expect(letterOf(-1), '?');
    });

    test('the paper overview is common for same and a roster for unique', () {
      final same = TestPaperOverview.fromJson({
        'common': [
          {'id': 'q', 'answer_index': 1, 'type': 'multiple_choice', 'answer_indexes': [0, 1]},
        ],
      });
      expect(same.isSame, isTrue);
      expect(same.common!.single.isMultipleChoice, isTrue);
      final unique = TestPaperOverview.fromJson({
        'variant_mode': 'unique',
        'students': [
          {'student_test_id': 'st', 'student': {'full_name': 'A'}, 'group': {'name': 'G'}},
        ],
      });
      expect(unique.common, isNull);
      expect(unique.students.single.groupName, 'G');
    });

    test('scans read their answers as strings and know when they matched', () {
      final s = PaperScan.fromJson({
        'state': 'reading',
        'read_answers': {'1': 'B', '2': null},
        'confidence': 1,
        'student': {'student_test_id': 'st', 'full_name': 'A'},
      });
      expect(s.readAnswers, {'1': 'B', '2': null});
      expect(s.isReading && s.isMatched, isTrue);
      expect(s.confidence, 1.0);
      expect(PaperScan.fromJson({'read_answers': 'x'}).readAnswers, isEmpty);
    });
  });
}
