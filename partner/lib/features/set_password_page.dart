import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers.dart';

class SetPasswordPage extends ConsumerStatefulWidget {
  const SetPasswordPage({super.key});

  @override
  ConsumerState<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends ConsumerState<SetPasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    final forced = ref.read(authControllerProvider).partner?.mustChangePassword ?? true;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(_current.text, _next.text);
      if (!mounted) return;
      if (forced) {
        context.go('/orders');
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    // Forced (first login / admin reset) is non-dismissible; a voluntary change
    // from Profile can be backed out of.
    final forced = ref.watch(authControllerProvider).partner?.mustChangePassword ?? true;
    return PopScope(
      canPop: !forced,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Set your password'),
            automaticallyImplyLeading: !forced),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose a new password to secure your account.',
                  style: TextStyle(color: muted)),
              const SizedBox(height: 20),
              TextField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current (temporary) password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password (min 8 chars)'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: riderRed, fontSize: 13)),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
