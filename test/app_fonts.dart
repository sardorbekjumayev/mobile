import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts into the test binding.
///
/// `flutter test` does **not** register the families declared in `pubspec.yaml`
/// — every widget test renders text in the fallback. That is invisible in a
/// finder-based test and fatal in a golden, where the whole point is what the
/// screen looks like: without this, a golden of the welcome screen would show
/// the headline in the wrong typeface and happily match itself forever.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const families = {
    'Figtree': [
      'assets/fonts/Figtree-Regular.ttf',
      'assets/fonts/Figtree-Medium.ttf',
      'assets/fonts/Figtree-SemiBold.ttf',
      'assets/fonts/Figtree-Bold.ttf',
    ],
    'Newsreader': [
      'assets/fonts/Newsreader-Regular.ttf',
      'assets/fonts/Newsreader-Medium.ttf',
    ],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
  // Material's own icons, so a golden shows the icon rather than a blank box.
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load().catchError((_) {});
  ui.PlatformDispatcher.instance.onError = null;
}
