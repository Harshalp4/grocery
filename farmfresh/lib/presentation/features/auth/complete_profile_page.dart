import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../providers/auth_controller.dart';

/// Mandatory profile step for new users: full name + mobile number. Name is
/// pre-filled when it came from Google / Apple.
class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  late final TextEditingController _name;
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(authControllerProvider).user?.name ?? '';
    _name = TextEditingController(text: existing);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.length < 2) { setState(() => _error = 'Enter your name'); return; }
    if (phone.length < 8) { setState(() => _error = 'Enter a valid mobile number'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier).completeProfile(name, phone);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prefilled = (ref.read(authControllerProvider).user?.name ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Almost done 🌿', style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text('Tell us who you are so we can deliver to you.',
                  style: TextStyle(fontSize: 13.5, color: c.muted)),
              const SizedBox(height: 24),

              _label(context, 'Full name', required: true),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                enabled: !_busy,
                decoration: const InputDecoration(
                    hintText: 'Your name', prefixIcon: Icon(Icons.person_outline, size: 20)),
              ),
              if (prefilled)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Pre-filled from Google / Apple · editable',
                      style: TextStyle(fontSize: 11, color: c.muted)),
                ),
              const SizedBox(height: 16),

              _label(context, 'Mobile number', required: true),
              Row(children: [
                SizedBox(
                  width: 60,
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
                    keyboardType: TextInputType.phone,
                    enabled: !_busy,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: '98XXXXXXXX'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create account'),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Google & Apple don\'t share a phone — mobile is required',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            text: text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.muted),
            children: required
                ? [TextSpan(text: ' *', style: TextStyle(color: context.colors.gold, fontWeight: FontWeight.w800))]
                : null,
          ),
        ),
      );
}
