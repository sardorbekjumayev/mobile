import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/session_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// M2 — phone entry, with the design's own 12-key pad rather than the system
/// keyboard, so the layout below it never jumps.
///
/// "Continue" asks `POST /auth/lookup` whether the number belongs to a student
/// or a teacher, and says which. That endpoint is a deliberate, bounded leak —
/// see its handler for what it refuses to answer and why. The screen's own rule
/// is that a lookup which *fails* never blocks anyone: only a definite
/// `found: false` stops here, and everything else carries on to the password
/// screen.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  /// National digits after the `+998` prefix: `90 123 45 67`.
  String _digits = '';

  bool _busy = false;

  /// Null until the number is nine digits long and the lookup has answered.
  PhoneLookup? _result;

  static const _maxDigits = 9;

  bool get _isComplete => _digits.length == _maxDigits;

  bool get _canContinue => !_busy && (_result?.found ?? false);

  _CardState get _cardState {
    if (!_isComplete || _busy) return _CardState.idle;
    return switch (_result) {
      null => _CardState.idle,
      PhoneLookup(found: false) => _CardState.notFound,
      PhoneLookup(role: UserRole.teacher) => _CardState.teacher,
      PhoneLookup(role: UserRole.student) => _CardState.student,
      // Found, but the lookup could not say who — an offline or rate-limited
      // answer. Neutral card, and the button still works.
      _ => _CardState.idle,
    };
  }

  /// `998901234567` — what `POST /auth/login` expects.
  String get _e164 => '998$_digits';

  void _push(String d) {
    if (_digits.length >= _maxDigits) return;
    setState(() => _digits += d);
    if (_isComplete) _lookup();
  }

  void _pop() {
    if (_digits.isEmpty) return;
    setState(() {
      _digits = _digits.substring(0, _digits.length - 1);
      _result = null;
      _busy = false;
    });
  }

  /// Runs as soon as the ninth digit lands, the way the template's card
  /// resolves the moment the number is complete. Deleting a digit clears it
  /// again — a card that still says "Teacher" under a number the user is busy
  /// editing is worse than no card.
  Future<void> _lookup() async {
    final phone = _e164;
    setState(() {
      _busy = true;
      _result = null;
    });

    final result = await context.read<AuthRepository>().lookup(phone);
    // A slow answer for a number the user has since edited is stale; drop it.
    if (!mounted || phone != _e164) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  void _continue() {
    final result = _result;
    if (result == null || !result.found) return;
    context.go('/login/password', extra: LoginTarget(phone: _e164, role: result.role));
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
              // One card, three identities — the template's "detection card".
              // It never stacks a second message under itself: this screen has a
              // keypad below it and no room to grow.
              _DetectionCard(state: _cardState, busy: _busy),
              const Spacer(),
              _Keypad(onDigit: _push, onBackspace: _pop),
              const SizedBox(height: 14),
              BrandButton(
                label: s.continueLabel,
                busy: _busy,
                onPressed: _canContinue ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the phone screen hands the password screen.
///
/// [role] is null when the lookup could not be made — offline, rate limited —
/// in which case the password screen simply shows no badge. It is never a
/// reason to refuse the login.
class LoginTarget {
  const LoginTarget({required this.phone, this.role});

  /// `998901234567`.
  final String phone;
  final UserRole? role;
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

/// The three things the phone screen's one card can be.
enum _CardState { idle, student, teacher, notFound }

/// The template's "detection card": the same slot says what the app knows about
/// the number, and changes identity as it learns.
///
/// One card rather than a hint plus an error plus a badge, because there is a
/// keypad underneath and no vertical room for a second message — and because
/// the three states are mutually exclusive anyway.
class _DetectionCard extends StatelessWidget {
  const _DetectionCard({required this.state, required this.busy});

  final _CardState state;

  /// The lookup is in flight: the icon spins rather than the card flickering
  /// through a wrong identity on the way to the right one.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final (title, text, icon, accent, tint) = switch (state) {
      _CardState.teacher => (
          s.roleTeacher,
          s.foundBody,
          Icons.co_present_rounded,
          AppColors.violet,
          AppColors.violetTint,
        ),
      _CardState.student => (
          s.roleStudent,
          s.foundBody,
          Icons.school_rounded,
          AppColors.blueDark,
          AppColors.blueTint,
        ),
      _CardState.notFound => (
          s.phoneNotFoundTitle,
          s.phoneNotFound,
          Icons.error_outline_rounded,
          AppColors.clay,
          AppColors.clayTint,
        ),
      _CardState.idle => (
          s.phoneHint,
          s.phoneHintText,
          Icons.badge_outlined,
          AppColors.muted,
          AppColors.surface2,
        ),
    };

    final resolved = state != _CardState.idle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: resolved ? accent : AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: ValueKey(state),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: resolved ? accent : AppColors.track2,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
                bottomRight: Radius.circular(17),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
                  )
                : Icon(icon, size: 17, color: resolved ? Colors.white : AppColors.muted),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('phone-detection-title'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: resolved ? accent : AppColors.ink,
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
