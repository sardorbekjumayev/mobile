import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/features/teacher/teacher_material_screen.dart';

import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';
import '../widget_harness.dart';

/// The teacher's half of the app: home, groups, tests, creating a test from one
/// of several subjects or from their own material, paper tests and titul
/// scanning, reviewing sheets and the AI memory.
void main() {
  usePhoneView();

  Map<String, dynamic> topic(String id, String name) =>
      {'id': id, 'position': 1, 'name': name, 'is_custom': false};

  Map<String, dynamic> program(String subjectId) => {
        'subject': {'id': subjectId, 'name': subjectId == 's1' ? 'Matematika' : 'Fizika'},
        'subjects': [
          {'id': 's1', 'name': 'Matematika'},
          {'id': 's2', 'name': 'Fizika'},
        ],
        'branches': [
          {
            'id': subjectId == 's1' ? 'b1' : 'b2',
            'name': subjectId == 's1' ? 'Arifmetika' : 'Mexanika',
            'topics': [subjectId == 's1' ? topic('t1', 'Natural sonlar') : topic('t2', 'Nyuton qonunlari')],
          },
        ],
      };

  List<Map<String, dynamic>> groups() => [
        {'id': 'g1', 'name': 'Matematika · 9-sinf', 'subject_id': 's1', 'students_count': 11},
        {'id': 'g2', 'name': 'Fizika · 10-sinf', 'subject_id': 's2', 'students_count': 8},
      ];

  FakeApiClient createApi() => FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/group': groups(),
        'GET /teacher/program': (Object? q) => program(((q as Map?)?['subject_id'] as String?) ?? 's1'),
        'GET /teacher/quota': {'unlimited': true, 'remaining': 9999, 'limit': 9999},
      });

  testWidgets('home lists what needs attention and leads into the AI memory', (tester) async {
    final api = FakeApiClient({
      ...teacherStubs(),
      'GET /teacher/home': {
        'kpis': {'groups': 2, 'students': 31, 'tests_this_month': 4, 'avg_score': 72},
        'attention': [
          {'type': 'not_started', 'title': 'Unit 4', 'group_name': 'G', 'count': 5, 'test_id': 't1'},
          {'type': 'inactive', 'full_name': 'Temur Sultonov', 'days': 12},
        ],
      },
      'POST /teacher/knowledge/source/paging': {'data': []},
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('Unit 4'), findsOneWidget);
    expect(find.text('Temur Sultonov'), findsOneWidget);
    expect(find.text('Ochish'), findsNWidgets(1));
    expect(find.text('Ok'), findsOneWidget);

    await tester.tap(find.text('AI xotiraga yuklang'));
    await tester.pumpAndSettle();
    expect(find.text('Hali hech narsa yuklanmagan. Birinchi testingizni suratga olib yuklang.'), findsOneWidget);
  });

  testWidgets('a group roster names engagement in words and opens a student', (tester) async {
    final api = FakeApiClient({
      ...teacherStubs(),
      'GET /teacher/group/g1': {
        'id': 'g1',
        'name': 'Matematika · 9-sinf',
        'subject': 'Matematika',
        'students': [
          {'id': 's1', 'full_name': 'Madina Saidova', 'engagement': 'active', 'attendance_pct': 92, 'avg_score': 81},
          {'id': 's2', 'full_name': 'Temur Sultonov', 'engagement': 'inactive'},
        ],
      },
      'GET /teacher/student/s1': {
        'student': {'id': 's1', 'full_name': 'Madina Saidova', 'phone': '+998901112233'},
        'avg_score': 81,
        'attendance_pct': 92,
        'streak_days': 4,
        'advice': 'Geometriyaga e\'tibor bering.',
        'tests': [
          {'id': 't1', 'title': 'Unit 4', 'score': 81},
        ],
      },
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/teacher/group/g1');

    expect(find.text('Faol'), findsOneWidget);
    expect(find.text('Nofaol'), findsOneWidget);
    expect(find.text('Davomat 92%'), findsOneWidget);

    await tester.tap(find.text('Madina Saidova'));
    await tester.pumpAndSettle();
    expect(find.text('+998901112233'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('Geometriyaga e\'tibor bering.'), findsOneWidget);
  });

  testWidgets('a brand-new student is described in words, not zeroes', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/student/s9': {'student': {'id': 's9', 'full_name': 'Yangi O\'quvchi'}, 'state': 'new'},
      }),
    );
    await goTo(tester, '/teacher/student/s9');
    expect(find.text('Qo\'shilgan, lekin ilovani hali ochmagan'), findsOneWidget);
    expect(find.text('Davomat'), findsNothing);
  });

  group('test detail', () {
    // A participant row — name, sheet chip, score chip, upload and review
    // buttons — overflows at 390px; every test here opens that row.
    setUp(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
      view.physicalSize = const Size(640, 1000);
    });

    Map<String, dynamic> detail({bool published = true}) => {
          'test': {
            'id': 't1',
            'title': 'Unit 4 · Algebra',
            'subject': 'Matematika',
            'question_count': 20,
            'assigned': 2,
            'submitted': 1,
            'published_at': published ? '2026-09-01T00:00:00Z' : null,
            'solution_required': true,
            'solution_pages': 3,
          },
          'students': [
            {
              'student_id': 's1',
              'student_test_id': 'st1',
              'full_name': 'Ali Valiyev',
              'state': 'submitted',
              'score': 80,
              'solution_state': 'done',
            },
          ],
        };

    testWidgets('an unsent test says so; sending reports how many were notified', (tester) async {
      final api = FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/test/t1': detail(published: false),
        'POST /teacher/test/t1/publish': {'notified': 14},
      });
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/test/t1');

      expect(find.text('Test hali yuborilmagan — o\'quvchilar uni ko\'rmaydi'), findsOneWidget);
      await tester.tap(find.text('O\'quvchilarga yuborish'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('POST /teacher/test/t1/publish'));
      expect(find.text('Yuborildi · 14'), findsOneWidget);
    });

    testWidgets('the titul card offers the PDF and the variants', (tester) async {
      final api = FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/test/t1': detail(),
        'GET /teacher/test/t1/paper': {
          'variant_mode': 'same',
          'common': [
            {'id': 'q1', 'position': 1, 'text': '2 + 2 = ?', 'options': ['3', '4'], 'answer_index': 1},
          ],
        },
      });
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/test/t1');

      expect(find.text('Qog\'oz test va titul'), findsOneWidget);
      expect(find.text('PDF va titulni yuklab olish'), findsOneWidget);
      expect(find.text('Qayta yuborish'), findsOneWidget);
      expect(find.text('Tahlil tayyor'), findsOneWidget);

      await tester.tap(find.text('Variantlarni ko\'rish'));
      await tester.pumpAndSettle();
      expect(find.text('Umumiy variant'), findsOneWidget);
      expect(find.text('1. 2 + 2 = ?'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('each student row uploads a solution sheet in the teacher\'s name', (tester) async {
      final api = FakeApiClient({...teacherStubs(), 'GET /teacher/test/t1': detail()});
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/test/t1');

      await tester.scrollUntilVisible(find.byTooltip('Yechim varag\'ini yuklash'), 200);
      await tester.tap(find.byTooltip('Yechim varag\'ini yuklash'));
      await tester.pumpAndSettle();

      // The student's own screen, in teacher mode: their name, the teacher's
      // copy, and the page count the test asked for.
      expect(find.text('Ali Valiyev'), findsOneWidget);
      expect(find.textContaining('O\'quvchi qog\'ozda ishlagan'), findsOneWidget);
      expect(find.text('Ishlangan varag\'ingizni yuklang'), findsNothing);
      expect(find.text('0/3'), findsOneWidget);
      await tester.tap(find.text('Yuklash'));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.endsWith('/solution')), isEmpty);
    });

    testWidgets('the scan shortcut opens the titul scanner', (tester) async {
      final api = FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/test/t1': detail(),
        'GET /teacher/test/t1/scan': [],
      });
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/test/t1');
      await tester.tap(find.text('Qog\'oz javoblarini skanerlash'));
      await tester.pumpAndSettle();
      expect(find.textContaining('To\'ldirilgan titullarni suratga oling'), findsOneWidget);
      expect(find.text('Hali skan qilingan varaq yo\'q.'), findsOneWidget);
    });
  });

  testWidgets('the scanner offers camera or gallery and attaches an unmatched sheet', (tester) async {
    // An unmatched scan row (code, chip, assign button) overflows at 390px.
    useWideView(tester);
    final api = FakeApiClient({
      ...teacherStubs(),
      'GET /teacher/test/t1/scan': [
        {'id': 'sc1', 'state': 'unmatched', 'read_code': 'P-0042'},
        {
          'id': 'sc2',
          'state': 'graded',
          'student': {'student_test_id': 'st2', 'full_name': 'Madina Saidova', 'score': 90},
        },
      ],
      'GET /teacher/test/t1': {
        'test': {'id': 't1', 'title': 'T'},
        'students': [
          {'student_id': 's1', 'student_test_id': 'st1', 'full_name': 'Ali Valiyev', 'state': 'assigned'},
        ],
      },
      'POST /teacher/scan/assign': null,
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/teacher/test/t1/scan');

    expect(find.text('P-0042'), findsOneWidget);
    expect(find.text('O\'quvchi topilmadi'), findsOneWidget);
    expect(find.text('Baholandi'), findsOneWidget);

    await tester.tap(find.text('Suratlarni tanlash'));
    await tester.pumpAndSettle();
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galereya'), findsOneWidget);
    // Dismiss the source sheet without picking — no platform channel is touched.
    await tester.tapAt(const Offset(320, 40));
    await tester.pumpAndSettle();

    await tester.tap(find.text('O\'quvchini biriktirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ali Valiyev'));
    await tester.pumpAndSettle();
    expect(api.bodies['POST /teacher/scan/assign'], {'scan_id': 'sc1', 'student_test_id': 'st1'});
  });

  testWidgets('a review correction re-sends the whole sheet in letters', (tester) async {
    final api = FakeApiClient({
      ...teacherStubs(),
      'GET /teacher/test/t1/student/st1': {
        'student': {'full_name': 'Ali Valiyev'},
        'score': 50,
        'questions': [
          {'question_id': 'q1', 'position': 1, 'text': 'Birinchi', 'options': ['a', 'b'], 'correct_index': 1, 'chosen_index': 0},
          {'question_id': 'q2', 'position': 2, 'text': 'Ikkinchi', 'options': ['c', 'd'], 'correct_index': 0, 'chosen_index': 0},
        ],
      },
      'POST /teacher/test/t1/student/st1/correct': {'score': 100, 'correct_count': 2, 'total': 2},
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/teacher/test/t1/student/st1/review');

    expect(find.text('Ali Valiyev'), findsOneWidget);
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To\'g\'irlashni saqlash'));
    await tester.pumpAndSettle();
    expect(api.bodies['POST /teacher/test/t1/student/st1/correct'], {
      'answers': {'1': 'B', '2': 'A'},
    });
  });

  testWidgets('a sheet with a matching question cannot be corrected here', (tester) async {
    final api = FakeApiClient({
      ...teacherStubs(),
      'GET /teacher/test/t1/student/st1': {
        'student': {'full_name': 'Ali'},
        'questions': [
          {
            'question_id': 'q1',
            'position': 1,
            'type': 'drag_and_drop',
            'text': 'Moslang',
            'items': ['Suv'],
            'targets': ['H2O'],
            'correct': [0],
            'drag_answer': [0],
          },
        ],
      },
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/teacher/test/t1/student/st1/review');
    expect(find.textContaining('web panelda tahrirlang'), findsOneWidget);
    await tester.tap(find.text('To\'g\'irlashni saqlash'));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.endsWith('/correct')), isEmpty);
  });

  testWidgets('a unique test lists students, each with their own paper', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/test/t1/paper': {
          'variant_mode': 'unique',
          'students': [
            {'student_test_id': 'st1', 'student': {'full_name': 'Ali Valiyev'}, 'group': {'name': 'G'}},
          ],
        },
        'GET /teacher/test/t1/paper/st1': {
          'student': {'full_name': 'Ali Valiyev'},
          'group': {'name': 'G'},
          'questions': [
            {'id': 'q', 'position': 1, 'type': 'image_based', 'text': 'Rasm', 'options': ['x'], 'answer_index': 0},
          ],
        },
      }),
    );
    await goTo(tester, '/teacher/test/t1/paper');
    await tester.tap(find.text('Ali Valiyev'));
    await tester.pumpAndSettle();
    expect(find.text('1. Rasm'), findsOneWidget);
    expect(find.text('Fayl biriktirilmagan'), findsOneWidget);
  });

  group('create test', () {
    testWidgets('a teacher of several subjects switches subject; groups follow it', (tester) async {
      final api = createApi();
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/create-test');

      expect(find.text('Matematika'), findsOneWidget);
      expect(find.text('Fizika'), findsOneWidget);
      expect(find.text('Matematika · 9-sinf'), findsOneWidget);
      expect(find.text('Fizika · 10-sinf'), findsNothing);

      await tester.tap(find.text('Fizika'));
      await tester.pumpAndSettle();
      expect(api.bodies['GET /teacher/program'], {'subject_id': 's2'});
      expect(find.text('Fizika · 10-sinf'), findsOneWidget);
      expect(find.text('Matematika · 9-sinf'), findsNothing);

      await tester.tap(find.text('Mavzu').last);
      await tester.pumpAndSettle();
      expect(find.text('Mexanika'), findsOneWidget);
      expect(find.text('Arifmetika'), findsNothing);
      await tester.tap(find.text('Nyuton qonunlari'));
      await tester.pumpAndSettle();
      expect(find.text('Mexanika · Nyuton qonunlari'), findsOneWidget);
    });

    testWidgets('a single-subject teacher sees no subject picker', (tester) async {
      final api = FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/group': [groups().first],
        'GET /teacher/program': {
          'subject': {'id': 's1', 'name': 'Matematika'},
          'subjects': [
            {'id': 's1', 'name': 'Matematika'},
          ],
          'branches': [],
        },
        'GET /teacher/quota': {'unlimited': true},
      });
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/create-test');
      expect(find.text('Fan'), findsNothing);
      expect(find.text('Matematika · 9-sinf'), findsOneWidget);
    });

    testWidgets('generating sends the chosen topic, groups and settings', (tester) async {
      final api = createApi()
        ..responses['POST /teacher/test/generate'] = {'job_id': 'j1', 'test_id': 'tx'}
        ..responses['GET /teacher/test/generate/j1'] = {'state': 'running', 'progress': 0.4};
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/create-test');

      await tester.tap(find.text('Mavzu').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Natural sonlar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Testni yaratish'), 300);
      await tester.tap(find.text('Testni yaratish'));
      await tester.pump();
      await tester.pump();

      final body = api.bodies['POST /teacher/test/generate']! as Map;
      expect(body['topic_id'], 't1');
      expect(body['group_ids'], ['g1']);
      expect(body['question_count'], 15);
      expect(body['time_limit_min'], 25);
      expect(body['difficulty'], 'mixed');
      await tester.pumpAndSettle();
      expect(find.text('Test tayyorlanmoqda'), findsOneWidget);
    });

    testWidgets('"O\'z materialimdan" opens the material screen from the form and the sheet', (tester) async {
      final api = createApi();
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/create-test');

      await tester.tap(find.text('+ O\'z materialimdan'));
      await tester.pumpAndSettle();
      expect(find.text('O\'z materialim'), findsOneWidget);
      expect(find.text('Arifmetika'), findsOneWidget);
      expect(find.text('Fayllar · 0/6'), findsOneWidget);
      expect(find.text('PDF / DOCX'), findsOneWidget);

      // Nothing picked: the upload button does not reach the server.
      await tester.tap(find.text('Yuklash va o\'qish'));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('POST /teacher/material/upload')));

      Navigator.of(tester.element(find.byType(TeacherMaterialScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mavzu').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('O\'z materialimdan'));
      await tester.pumpAndSettle();
      expect(find.text('O\'z materialim'), findsOneWidget);
    });

    testWidgets('material needs a section to go into', (tester) async {
      final api = FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/group': [groups().first],
        'GET /teacher/program': {
          'subject': {'id': 's1', 'name': 'Matematika'},
          'branches': [],
        },
        'GET /teacher/quota': {'unlimited': true},
      });
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/create-test');
      await tester.tap(find.text('+ O\'z materialimdan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Avval bo\'lim qo\'shing'), findsOneWidget);
    });

    testWidgets('a subject with no groups says so', (tester) async {
      final api = createApi()..responses['GET /teacher/group'] = [groups().first];
      await pumpApp(tester, api: api, tokens: signedInTokens);
      await goTo(tester, '/teacher/create-test');
      await tester.tap(find.text('Fizika'));
      await tester.pumpAndSettle();
      expect(find.text('Bu fan bo\'yicha guruhingiz yo\'q.'), findsOneWidget);
    });
  });

  testWidgets('the AI memory lists uploads, opens one and deletes it', (tester) async {
    var deleted = false;
    final api = FakeApiClient({
      ...teacherStubs(),
      'POST /teacher/knowledge/source/paging': (Object? _) => {
            'data': deleted
                ? []
                : [
                    {
                      'id': 'k1',
                      'title': '9-sinf algebra',
                      'kind': 'test',
                      'state': 'done',
                      'pages': 3,
                      'result': {'questions': 12, 'lessons': 4},
                    },
                  ],
          },
      'GET /teacher/knowledge/source/k1': {
        'id': 'k1',
        'title': '9-sinf algebra',
        'state': 'done',
        'result': {'summary': 'Kvadrat tenglamalar', 'topics': [{'label': 'Diskriminant'}]},
        'knowledge': [
          {'id': 'i1', 'kind': 'misconception', 'topic_label': 'Diskriminant', 'content': 'Ishorani unutadi', 'shared': true},
        ],
      },
      'DELETE /teacher/knowledge/source/k1': (Object? _) {
        deleted = true;
        return null;
      },
    });
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/teacher/knowledge');

    expect(find.text('9-sinf algebra'), findsOneWidget);
    expect(find.text('Tayyor'), findsOneWidget);
    expect(find.textContaining('12 savol · 4 xulosa'), findsOneWidget);

    await tester.tap(find.text('9-sinf algebra'));
    await tester.pumpAndSettle();
    expect(find.text('Ishorani unutadi'), findsOneWidget);
    expect(find.text('Tipik xato'), findsOneWidget);
    expect(find.textContaining('Hammaga ulashiladi'), findsOneWidget);

    await tester.tap(find.byTooltip('O\'chirish'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'O\'chirish'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('DELETE /teacher/knowledge/source/k1'));
    expect(find.textContaining('Hali hech narsa yuklanmagan'), findsOneWidget);
  });

  testWidgets('a knowledge upload needs photos and a name', (tester) async {
    final api = FakeApiClient({...teacherStubs(), 'POST /teacher/knowledge/source/paging': {'data': []}});
    await pumpApp(tester, api: api, tokens: signedInTokens);
    await goTo(tester, '/teacher/knowledge-upload');
    expect(find.text('Ishlangan varaq'), findsOneWidget);
    expect(find.text('0/30'), findsOneWidget);
    await tester.tap(find.text('Yuklash va tahlil qilish'));
    await tester.pumpAndSettle();
    expect(api.calls, isNot(contains('POST /teacher/knowledge/source')));
  });

  testWidgets('the groups tab shows each group\'s stats and the register button', (tester) async {
    await pumpApp(
      tester,
      tokens: signedInTokens,
      api: FakeApiClient({
        ...teacherStubs(),
        'GET /teacher/group': [
          {
            'id': 'g1',
            'name': 'Matematika · 9-sinf',
            'subject': 'Matematika',
            'level': '9',
            'room': '301',
            'students_count': 11,
            'avg_score': 54,
            'attendance_pct': null,
          },
        ],
      }),
    );
    await tester.tap(find.text('Guruhlar').last);
    await tester.pumpAndSettle();
    expect(find.text('Matematika · 9-daraja · 301-xona'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('54'), findsWidgets);
    expect(find.text('Yo\'qlama'), findsOneWidget);
  });
}
