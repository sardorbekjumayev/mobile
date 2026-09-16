import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_api_client.dart';

/// Screens are drawn for a phone; the 800x600 default surface pushes buttons
/// out of the hit test.
void usePhoneView() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });
}

/// A wider surface for screens whose rows overflow a 390px phone today (see the
/// report accompanying these tests) — so the behaviour under test is checked
/// without the overflow failing it first.
void useWideView(WidgetTester tester) {
  tester.view.physicalSize = const Size(640, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Pushes [location] on the app's own router, the way a tap would.
Future<void> goTo(WidgetTester tester, String location, {Object? extra}) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).push(location, extra: extra);
  await tester.pumpAndSettle();
}

/// Replaces the whole stack — for the sign-in screens, which are `go` targets.
Future<void> goReplace(WidgetTester tester, String location, {Object? extra}) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location, extra: extra);
  await tester.pumpAndSettle();
}

/// The stubs a signed-in student's shell needs before any screen is opened.
Map<String, dynamic> studentStubs() => {
      'GET /auth/me': identityJson(),
      'GET /settings': settingsJson,
      'GET /home': {'greeting': 'day', 'empty_state': 'no_group'},
      'GET /group': const [],
    };

/// The same for a teacher.
Map<String, dynamic> teacherStubs() => {
      'GET /auth/me': identityJson(role: 'teacher'),
      'GET /settings': settingsJson,
      'GET /teacher/home': {'kpis': {}, 'attention': []},
      'GET /teacher/group': const [],
    };
