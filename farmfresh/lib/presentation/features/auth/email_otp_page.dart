import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../providers/auth_controller.dart';

/// Enter the 6-digit code sent to the email. Routes new users to the profile
/// step and returning users straight to Home.
class EmailOtpPage extends ConsumerStatefulWidget {
  const EmailOtpPage({super.key, required this.email, this.devOtp});
  final String email;
  final String? devOtp;

  @override
  ConsumerState<EmailOtpPage> createState() => _EmailOtpPageState();
}

class _EmailOtpPageState extends ConsumerState<EmailOtpPage> {
  final _otp = TextEditingController();
  bool _busy = false;
  String? _error;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.devOtp != null) _otp.text = widget.devOtp!; // dev auto-fill
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) { t.cancel(); setState(() => _resendIn = 0); }
      else { setState(() => _resendIn--); }
    });
  }

  @override
  void dispose() {
    _otp.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 4) {
      setState(() => _error = 'Enter the code from your email');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final complete = await ref
          .read(authControllerProvider.notifier)
          .verifyEmailOtp(widget.email, _otp.text.trim());
      if (!mounted) return;
      context.go(complete ? '/home' : '/complete-profile');
    } catch (e) {
      if (mounted) setState(() => _error = 'Invalid or expired code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _busy = true; _error = null; });
    try {
      final res = await ref.read(authControllerProvider.notifier).requestEmailOtp(widget.email);
      if (res.devOtp != null) _otp.text = res.devOtp!;
      _startTimer();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter the code', style: context.text.headlineSmall),
              const SizedBox(height: 6),
              Wrap(children: [
                Text('Sent to ', style: TextStyle(fontSize: 13.5, color: c.muted)),
                Text(widget.email,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('Edit',
                      style: TextStyle(fontSize: 13.5, color: c.green, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 22),
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 10),
                decoration: const InputDecoration(counterText: ''),
                onSubmitted: (_) => _busy ? null : _verify(),
              ),
              if (widget.devOtp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Dev code: ${widget.devOtp} (auto-filled)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: c.gold)),
                ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
              const SizedBox(height: 12),
              Center(
                child: _resendIn > 0
                    ? Text('Resend code in 0:${_resendIn.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12.5, color: c.muted))
                    : TextButton(onPressed: _busy ? null : _resend, child: const Text('Resend code')),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
