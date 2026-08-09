import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';
import '../core/motion.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesState = ref.watch(messageNotifierProvider);
    final messagesFuture = ref.watch(messageListProvider).asData?.value ?? [];
    final msgs = messagesState.isNotEmpty ? messagesState : messagesFuture;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inbox Feed'),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, size: 18),
            onPressed: () {
              ref.invalidate(messageListProvider);
            },
          ),
        ],
      ),
      body: msgs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox, size: 56, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Share a message from WhatsApp to ASTRA',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ).withPremiumEntry()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: msgs.length,
              itemBuilder: (context, index) {
                final msg = msgs[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withAlpha(20)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(30),
                      child: Icon(LucideIcons.messageSquare, color: AppTheme.primary, size: 18),
                    ),
                    title: Text(
                      msg.text,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Received: ${DateFormat('MMM dd, hh:mm a').format(msg.receivedAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                      ),
                    ),
                    trailing: msg.processed
                        ? Icon(LucideIcons.checkCircle2, color: AppTheme.success, size: 18)
                        : Icon(LucideIcons.clock, color: AppTheme.warning, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message: ${msg.text}')),
                      );
                    },
                  ),
                ).withPremiumEntry(delayMs: index * 40);
              },
            ),
    );
  }
}
