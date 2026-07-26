import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_ext.dart';
import '../../providers/repository_providers.dart';

class _Message {
  const _Message(this.text, {required this.fromMe});
  final String text;
  final bool fromMe;
}

/// Screen 12 — AI Grocery Assistant. Chat with canned/AI-backed replies.
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[
    const _Message(
      '👋 Hi! I can plan your monthly kirana, suggest health baskets, or fit a '
      'budget. Try a prompt below.',
      fromMe: false,
    ),
  ];
  bool _thinking = false;

  static const _suggestions = [
    'Create monthly grocery list for family of 4',
    'Suggest high-protein vegetarian groceries',
    'I have ₹5000 budget, make monthly kirana',
    'What can I cook from rice, dal and ghee?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String prompt) async {
    if (prompt.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(prompt, fromMe: true));
      _thinking = true;
      _input.clear();
    });
    _scrollToEnd();
    final reply = await ref.read(assistantRepositoryProvider).ask(prompt);
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(reply, fromMe: false));
      _thinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Grocery Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in _messages) _Bubble(message: m),
                if (_thinking)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text('Try asking', style: context.text.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: c.beige,
                        side: BorderSide(color: c.line),
                        onPressed: () => _send(s),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                          hintText: 'Ask the assistant…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: () => _send(_input.text),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final me = message.fromMe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.84),
        decoration: BoxDecoration(
          color: me ? c.green : c.greenSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(me ? 16 : 4),
            bottomRight: Radius.circular(me ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: me ? Colors.white : c.ink,
          ),
        ),
      ),
    );
  }
}
