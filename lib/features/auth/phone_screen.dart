import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// M2 — phone entry, with the design's own 12-key pad rather than the system
/// keyboard, so the layout below it never jumps.
///
/// Validation is entirely client-side: there is no "does this number exist"
/// endpoint, and adding one would hand anyone a way to walk the +998 range and
/// learn which numbers are enrolled.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  /// National digits after the `+998` prefix: `90 123 45 67`.
  String _digits = '';

  static const _maxDigits = 9;

  bool get _isComplete => _digits.length == _maxDigits;

  /// `998901234567` — what `POST /auth/login` expects.
  String get _e164 => '998$_digits';

  void _push(String d) {
    if (_digits.length >= _maxDigits) return;
    setState(() => _digits += d);
  }

  void _pop() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleBack(onTap: () => context.go('/welcome')),
              const SizedBox(height: 22),
              Text(s.phoneTitle, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                s.phoneBody,
                style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              _PhoneField(digits: _digits),
              const SizedBox(height: 14),
              _HintCard(title: s.phoneHint, text: s.phoneHintText),
              const Spacer(),
              _Keypad(onDigit: _push, onBackspace: _pop),
              const SizedBox(height: 14),
              BrandButton(
                label: s.continueLabel,
                onPressed: _isComplete
                    ? () => context.go('/login/password', extra: _e164)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `90 123 45 67` — grouped as the country writes it, so a mistyped digit is
/// visible at a glance.
String formatUzPhone(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 2 || i == 5 || i == 7) b.write(' ');
    b.write(digits[i]);
  }
  return b.toString();
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.digits});

  final String digits;

  @override
  Widget build(BuildContext context) {
    final filled = digits.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppShapes.fieldRadius,
        border: Border.all(
          color: filled ? AppColors.blueLight2 : AppColors.line,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Text(
            '🇺🇿 +998',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.body),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 22, color: AppColors.track2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              filled ? formatUzPhone(digits) : '__ ___ __ __',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: filled ? AppColors.ink : AppColors.faint2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.blueTint2,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: AppColors.blueLight5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BlobAvatar(
            text: '',
            icon: Icons.info_outline_rounded,
            size: 34,
            background: AppColors.blueTint,
            foreground: AppColors.blueDark,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(fontSize: 11.5, height: 1.45, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = <Widget>[
      for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        _Key(label: d, onTap: () => onDigit(d)),
      const SizedBox.shrink(),
      _Key(label: '0', onTap: () => onDigit('0')),
      _Key(icon: Icons.backspace_outlined, onTap: onBackspace),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.85,
      children: keys,
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 20, color: AppColors.body)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, size: 17, color: AppColors.body),
        ),
      ),
    );
  }
}
