import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';

/// M19b — `POST /auth/change-password`.
///
/// Reachable two ways: forced after a first sign-in (`must_change_password`),
/// where every other screen stays blocked until it succeeds, and voluntarily
/// from settings. Succeeding revokes every other session.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _minLength = 8;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    if (_next.text.length < _minLength) {
      setState(() => _error = s.passwordTooShort);
      return;
    }
    if (_next.text != _repeat.text) {
      setState(() => _error = s.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final session = context.read<SessionController>();
    try {
      await session.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      context.go(session.isTeacher ? '/teacher/home' : '/student/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.forced,
        title: Text(widget.forced ? '' : s.changePassword),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.changePasswordTitle, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                s.changePasswordBody,
                style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              _Field(controller: _current, label: s.currentPassword),
              const SizedBox(height: 12),
              _Field(controller: _next, label: s.newPassword),
              const SizedBox(height: 12),
              _Field(controller: _repeat, label: s.repeatPassword),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  key: const Key('change-password-error'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.clay),
                ),
              ],
              const SizedBox(height: 28),
              BrandButton(label: s.save, busy: _busy, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppShapes.fieldRadius,
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.faint, fontSize: 13.5),
        ),
        style: const TextStyle(fontSize: 15, color: AppColors.ink),
      ),
    );
  }
}
