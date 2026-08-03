import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../providers/auth_controller.dart';

/// Edit profile — name + mobile are editable; email is the login identity and
/// is shown read-only. Saves via PUT /auth/me.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
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
    if (name.length < 2) {
      setState(() => _error = 'Enter your name');
      return;
    }
    if (phone.length < 8) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(name, phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final email = ref.watch(authControllerProvider).user?.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label(context, 'Name', required: true),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                enabled: !_busy,
                decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline, size: 20)),
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
              const SizedBox(height: 16),

              _label(context, 'Email (login)'),
              TextField(
                readOnly: true,
                enabled: false,
                controller: TextEditingController(
                    text: email?.isNotEmpty == true ? email : '—'),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                    suffixIcon: Icon(Icons.lock_outline, size: 18)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Your email is used to sign in and can\'t be changed',
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text, {bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            text: text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.muted),
            children: required
                ? [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(
                            color: context.colors.gold,
                            fontWeight: FontWeight.w800))
                  ]
                : null,
          ),
        ),
      );
}
