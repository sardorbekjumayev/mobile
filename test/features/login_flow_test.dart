import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';

/// The sign-in flow end to end: number → lookup → password.
///
/// `/auth/lookup` is a convenience, and the tests that matter most are the ones
/// where it fails: a rate limit or a dead connection must never stand between a
/// student and a login form that would have worked.
void main() {
  setUp(() {
    // The phone screen is a full-height design with a 12-key pad under it; the
    // 800x600 default surface overflows it and the keys fall outside the hit
    // test. A phone-shaped window is what this screen is drawn for.
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  Future<void> enterNumber(WidgetTester tester) async {
    await tester.tap(find.textContaining('Raqam bilan'));
    await tester.pumpAndSettle();
    for (final d in '901110011'.split('')) {
      await tester.tap(find.widgetWithText(InkWell, d));
      await tester.pump();
    }
  }

  Finder cardTitle() => find.byKey(const Key('phone-detection-title'));

  testWidgets('the card names a teacher as soon as the ninth digit lands', (tester) async {
    await pumpApp(tester, api: FakeApiClient({
      'POST /auth/lookup': {'found': true, 'role': 'teacher'},
    }));

    await enterNumber(tester);

    expect(tester.widget<Text>(cardTitle()).data, 'O\'qituvchi');
    // Still on the phone screen — the card resolves before "Davom etish".
    expect(find.text('Davom etish'), findsOneWidget);
  });

  testWidgets('a student number is named as a student', (tester) async {
    await pumpApp(tester, api: FakeApiClient({
      'POST /auth/lookup': {'found': true, 'role': 'student'},
    }));

    await enterNumber(tester);

    expect(tester.widget<Text>(cardTitle()).data, 'O\'quvchi');
  });

  testWidgets('a number the server does not know cannot continue', (tester) async {
    await pumpApp(tester, api: FakeApiClient({
      'POST /auth/lookup': {'found': false},
    }));

    await enterNumber(tester);

    expect(tester.widget<Text>(cardTitle()).data, 'Raqam topilmadi');
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    // The button is dead, not merely unhelpful: still the phone screen.
    expect(find.text('Kirish'), findsNothing);
  });

  testWidgets('a lookup that fails lets the user through anyway', (tester) async {
    // Rate limited, offline, 500 — none of them is evidence about the number,
    // and refusing here would lock out a student whose password is correct.
    await pumpApp(tester, api: FakeApiClient(const {}));

    await enterNumber(tester);

    // The card stays neutral, because nothing was learned…
    expect(tester.widget<Text>(cardTitle()).data, 'Hisobni o\'quv markaz ochadi');
    // …and the button still works.
    await tester.tap(find.text('Davom etish'));
    await tester.pumpAndSettle();
    expect(find.text('Kirish'), findsOneWidget);
  });
}
