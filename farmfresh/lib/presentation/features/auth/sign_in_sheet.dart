import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/social_sign_in.dart';
import '../../../core/theme/theme_ext.dart';
import '../../providers/auth_controller.dart';
import 'social_buttons.dart';

/// Bottom sheet shown when a guest attempts an account action. Offers email
/// (→ full sign-in screen) plus Google / Apple inline.
class SignInSheet extends ConsumerStatefulWidget {
  const SignInSheet({super.key});

  @override
  ConsumerState<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<SignInSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _social(Future<bool?> Function() run) async {
    setState(() { _busy = true; _error = null; });
    try {
      final complete = await run();
      if (complete == null || !mounted) return; // cancelled
      Navigator.pop(context, true);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 38, height: 4,
                decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(9))),
          ),
          const SizedBox(height: 16),
          Container(
            width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(11)),
            child: Icon(Icons.lock_outline, color: c.green, size: 20),
          ),
          const SizedBox(height: 12),
          Text('Sign in to continue', style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text('Create a free account to add items and place orders.',
              style: TextStyle(fontSize: 13, color: c.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : () { Navigator.pop(context); context.push('/login'); },
            child: const Text('Continue with email'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Divider(color: c.line)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('or', style: TextStyle(fontSize: 12, color: c.muted))),
            Expanded(child: Divider(color: c.line)),
          ]),
          const SizedBox(height: 12),
          GoogleButton(
            onPressed: _busy ? null : () => _social(
                () => ref.read(authControllerProvider.notifier).signInWithGoogle())),
          const SizedBox(height: 10),
          AppleButton(
            onPressed: _busy ? null : () => _social(
                () => ref.read(authControllerProvider.notifier).signInWithApple())),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12.5)),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text('Not now', style: TextStyle(color: c.muted)),
          ),
        ],
      ),
    );
  }
}

/// Ensures the user is signed in before an account action. If already signed in,
/// returns true immediately; otherwise shows [SignInSheet] and returns whether
/// the user signed in.
Future<bool> ensureSignedIn(BuildContext context, WidgetRef ref) async {
  if (ref.read(authControllerProvider).isAuthenticated) return true;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const SignInSheet(),
  );
  return result ?? false;
}
