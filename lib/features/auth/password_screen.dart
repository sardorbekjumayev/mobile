import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/strings.dart';
import '../shared/widgets/primitives.dart';
import 'phone_screen.dart' show formatUzPhone;

/// M3 — password entry and the only call to `POST /auth/login`.
///
/// The prototype showed the account's name and center above the field. Real
/// sign-in cannot: resolving a name from a phone number before authentication
/// is the same oracle the single `20105` error code exists to prevent.
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.phone});

  /// `998901234567`.
  final String phone;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _busy = false;
  bool _canSubmit = false;
  String? _error;

  /// Shown under the error for `20105` only.
  ///
  /// A center admin signing in here gets exactly the same "wrong phone or
  /// password" as a student with a typo — deliberately, because naming the role
  /// would turn the form into a directory of which numbers are admins. The cost
  /// is that an admin has no way to tell they are simply in the wrong app, so
  /// the hint is shown to *everyone* who gets that error: it says nothing about
  /// the number that was typed.
  bool _showAdminHint = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy || _controller.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _showAdminHint = false;
    });

    final session = context.read<SessionController>();
    try {
      await session.signIn(phone: widget.phone, password: _controller.text);
      if (!mounted) return;
      // The router's redirect decides where to land — a first sign-in goes to
      // the forced password change, not to the home screen.
      context.go(session.status == SessionStatus.mustChangePassword
          ? '/change-password'
          : '/login/success');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _showAdminHint = e.isWrongCredentials;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = S.of(context).somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final national = widget.phone.startsWith('998') ? widget.phone.substring(3) : widget.phone;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.surface,
                shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
                child: InkWell(
                  onTap: () => context.go('/login/phone'),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded, size: 17, color: AppColors.body),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(s.passwordTitle, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: '${s.passwordBody} ',
                  children: [
                    TextSpan(
                      text: '+998 ${formatUzPhone(national)}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.muted),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: AppShapes.fieldRadius,
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.faint),
                    const SizedBox(width: 11),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        obscureText: _obscured,
                        autofocus: true,
                        onSubmitted: (_) => _signIn(),
                        onChanged: (value) => setState(() {
                          _canSubmit = value.isNotEmpty;
                          _error = null;
                        }),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: s.passwordField,
                          hintStyle: const TextStyle(color: AppColors.faint2, fontSize: 15),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _obscured = !_obscured),
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  key: const Key('login-error'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.clay, height: 1.45),
                ),
              ],
              if (_showAdminHint) ...[
                const SizedBox(height: 10),
                Text(
                  s.loginAdminHint,
                  key: const Key('login-admin-hint'),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
                ),
              ],
              const Spacer(),
              BrandButton(
                label: s.signIn,
                busy: _busy,
                onPressed: _canSubmit ? _signIn : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
