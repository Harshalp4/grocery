import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/social_sign_in.dart';
import '../../../core/config/brand.dart';
import '../../../core/theme/theme_ext.dart';
import '../../providers/auth_controller.dart';
import 'social_buttons.dart';

/// Sign in / sign up — email code first, then Google / Apple, then guest.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool _validEmail(String e) =>
      e.contains('@') && e.indexOf('@') > 0 && e.contains('.') && e.length >= 5;

  Future<void> _sendCode() async {
    final email = _email.text.trim().toLowerCase();
    if (!_validEmail(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final res = await ref.read(authControllerProvider.notifier).requestEmailOtp(email);
      if (!mounted) return;
      context.push('/login/otp', extra: {'email': email, 'devOtp': res.devOtp});
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send the code. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _social(Future<bool?> Function() run) async {
    setState(() { _busy = true; _error = null; });
    try {
      final complete = await run();
      if (complete == null || !mounted) return; // cancelled
      context.go(complete ? '/home' : '/complete-profile');
    } on SocialSignInException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 48, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 54, height: 54, alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: c.greenSoft, borderRadius: BorderRadius.circular(15)),
                child: Icon(Icons.eco, color: c.green, size: 28),
              ),
              const SizedBox(height: 18),
              Text('Sign in or sign up', style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text('Use your email, or continue with Google or Apple.',
                  style: TextStyle(fontSize: 13.5, color: c.muted)),
              const SizedBox(height: 26),

              Text('Email address',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_busy,
                decoration: const InputDecoration(
                  hintText: 'you@email.com',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
                onSubmitted: (_) => _busy ? null : _sendCode(),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _busy ? null : _sendCode,
                child: _busy ? const _Spin() : const Text('Send code'),
              ),

              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Divider(color: c.line)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or', style: TextStyle(fontSize: 12, color: c.muted))),
                Expanded(child: Divider(color: c.line)),
              ]),
              const SizedBox(height: 14),

              GoogleButton(
                onPressed: _busy ? null : () => _social(
                    () => ref.read(authControllerProvider.notifier).signInWithGoogle())),
              const SizedBox(height: 10),
              AppleButton(
                onPressed: _busy ? null : () => _social(
                    () => ref.read(authControllerProvider.notifier).signInWithApple())),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ],

              const SizedBox(height: 22),
              TextButton(
                onPressed: _busy ? null : () => context.go('/products'),
                child: const Text('Browse as guest'),
              ),
              const SizedBox(height: 6),
              Text('By continuing you agree to ${Brand.name}\'s Terms & Privacy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Spin extends StatelessWidget {
  const _Spin();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 20, width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
}
