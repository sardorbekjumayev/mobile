import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_smoke_test.dart' show pumpApp;
import '../fake_api_client.dart';

/// A regression test for two bugs `AsyncView.refresh()` has actually shipped
/// with:
///
///  1. `setState(() => _future = next)` — an assignment expression evaluates
///     to the value assigned, and `_future = next` is a `Future`, so that
///     one-liner handed `setState` a callback that returns a `Future`, which
///     `setState` throws on unconditionally.
///  2. Checking only `connectionState == waiting` to decide whether to show
///     a bare `LoadingView` — `FutureBuilder` carries the previous
///     snapshot's data into that same "waiting" state on every refresh, so
///     this replaced the whole screen, `RefreshIndicator` included, on every
///     pull — losing the very widget mid-gesture that was performing it.
///
/// Both threw (or would throw) on a real, ordinary pull-to-refresh, on every
/// screen built on `AsyncView` — which is why this exercises the actual
/// gesture end to end rather than calling `refresh()` directly.
void main() {
  testWidgets('pulling to refresh does not throw, and re-fetches', (tester) async {
    final api = FakeApiClient({
      'GET /auth/me': identityJson(role: 'teacher'),
      'GET /settings': settingsJson,
      'GET /teacher/home': {'kpis': {}, 'attention': []},
      'GET /teacher/group': <Map<String, dynamic>>[],
    });

    await pumpApp(tester, api: api, tokens: signedInTokens);

    expect(find.byType(RefreshIndicator), findsWidgets);
    expect(api.calls.where((c) => c == 'GET /teacher/home').length, 1);

    // The standard way to drive a `RefreshIndicator` in a widget test: a
    // downward fling on its scrollable child, starting from scroll offset 0.
    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // No FlutterError was thrown along the way, and the pull actually
    // triggered a second, real fetch rather than silently no-op'ing.
    expect(api.calls.where((c) => c == 'GET /teacher/home').length, greaterThanOrEqualTo(2));
  });
}
