import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../providers/auth_controller.dart';

/// Screen 2 — Login with real phone + OTP. In backend dev mode the OTP is
/// returned and shown here so it can be tested without SMS.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  bool _otpSent = false;
  bool _busy = false;
  String? _devOtp;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length < 8) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res =
          await ref.read(authControllerProvider.notifier).requestOtp(_phone.text.trim());
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _devOtp = res.devOtp;
        if (res.devOtp != null) _otp.text = res.devOtp!; // auto-fill in dev
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send OTP: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(
            _phone.text.trim(),
            _otp.text.trim(),
            name: _name.text.trim(),
          );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = 'Invalid or expired OTP');
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
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
          child: Column(
            children: [
              Icon(Icons.eco, size: 44, color: c.green),
              const SizedBox(height: 6),
              Text('Welcome to FarmFresh', style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text('Login to start your monthly kirana',
                  style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, 'Your name (optional)'),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'e.g. Harshal'),
                    ),
                    const SizedBox(height: 14),
                    _label(context, 'Mobile number'),
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: TextField(
                            readOnly: true,
                            controller: TextEditingController(text: '+91'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration:
                                const InputDecoration(hintText: '98XXXXXXXX'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (!_otpSent)
                      ElevatedButton(
                        onPressed: _busy ? null : _sendOtp,
                        child: _busy
                            ? const _Spinner()
                            : const Text('Send OTP'),
                      ),
                    if (_otpSent) ...[
                      _label(context, 'Enter OTP'),
                      TextField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8),
                        decoration: const InputDecoration(counterText: ''),
                      ),
                      if (_devOtp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Dev OTP: $_devOtp (auto-filled)',
                              style: TextStyle(fontSize: 11, color: c.gold)),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _busy ? null : _verify,
                        child: _busy
                            ? const _Spinner()
                            : const Text('Continue'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _sendOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12.5)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('or', style: TextStyle(fontSize: 12, color: c.muted)),
              const SizedBox(height: 16),
              GhostButton(
                label: 'Browse as Guest',
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 14),
              Text('By continuing you agree to Terms & Privacy (placeholder)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.muted)),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
