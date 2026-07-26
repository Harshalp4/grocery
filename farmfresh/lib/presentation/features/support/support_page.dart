import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/support_ticket.dart';
import '../../providers/auth_controller.dart';
import '../../providers/repository_providers.dart';

/// Help & Support — FAQ, contact info and raise/track tickets.
class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  static const _faq = <(String, String)>[
    ('How do I track my order?',
        'Open Profile → My Orders and tap an order to see its live status timeline.'),
    ('What payment methods are supported?',
        'Cash on Delivery for now. Online payments are coming soon.'),
    ('How do coupons work?',
        'Enter a code in the cart and tap Apply — the discount shows in your bill.'),
    ('Can I cancel an order?',
        'Yes, before it is dispatched — from the order detail screen.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final signedIn = ref.watch(authControllerProvider).isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          const SectionHeader('Frequently asked'),
          AppCard(
            child: Column(
              children: [
                for (final f in _faq)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 10),
                    title: Text(f.$1,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f.$2,
                            style: TextStyle(fontSize: 12.5, color: c.muted)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SectionHeader('Contact us'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.chat_outlined, size: 18, color: c.green),
                  const SizedBox(width: 8),
                  const Text('WhatsApp: +91 98200 00000',
                      style: TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.call_outlined, size: 18, color: c.green),
                  const SizedBox(width: 8),
                  const Text('Call: +91 98200 00000',
                      style: TextStyle(fontSize: 13)),
                ]),
              ],
            ),
          ),
          SectionHeader(
            'Your tickets',
            actionLabel: signedIn ? 'Raise a ticket' : null,
            onAction: signedIn ? () => _raiseTicket(context, ref) : null,
          ),
          if (!signedIn)
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Sign in to raise and track support tickets.',
                        style: TextStyle(fontSize: 13, color: c.muted)),
                  ),
                  TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign in')),
                ],
              ),
            )
          else
            ref.watch(myTicketsProvider).when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => AppCard(child: Text('Could not load: $e')),
                  data: (list) => list.isEmpty
                      ? AppCard(
                          child: Text('No tickets yet.',
                              style: TextStyle(color: c.muted)))
                      : Column(
                          children: [for (final t in list) _TicketCard(ticket: t)],
                        ),
                ),
        ],
      ),
    );
  }

  Future<void> _raiseTicket(BuildContext context, WidgetRef ref) async {
    final subject = TextEditingController();
    final message = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Raise a ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(hintText: 'Subject'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: message,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'How can we help?'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a subject and message first')),
        );
      }
      return;
    }
    try {
      await ref
          .read(supportRepositoryProvider)
          .raise(subject.text.trim(), message.text.trim());
      ref.invalidate(myTicketsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket raised — we\'ll get back to you')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit: $e')));
      }
    }
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final resolved = ticket.status != 'open';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ticket.subject,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: resolved ? c.greenSoft : c.goldSoft,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(ticket.status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: resolved ? c.green : c.gold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(ticket.message, style: TextStyle(fontSize: 12.5, color: c.muted)),
          if (ticket.reply != null && ticket.reply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: c.greenSoft, borderRadius: AppRadius.smAll),
              child: Text('Support: ${ticket.reply}',
                  style: TextStyle(fontSize: 12.5, color: c.green)),
            ),
          ],
        ],
      ),
    );
  }
}
