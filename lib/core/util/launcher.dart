import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/strings.dart';

/// Opens a support link, a policy PDF or a payment page in the device browser.
///
/// Payment in particular has to leave the app: Payme and Click both authorise
/// inside their own page, and an in-app webview is exactly where a bank's 3-D
/// Secure step breaks.
Future<void> openExternal(BuildContext context, String? url) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = S.of(context).somethingWentWrong;
  final uri = url == null ? null : Uri.tryParse(url);

  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
