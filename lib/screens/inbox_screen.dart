import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';

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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(messageListProvider);
            },
          ),
        ],
      ),
      body: msgs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Share a message from WhatsApp to ASTRA',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: msgs.length,
              itemBuilder: (context, index) {
                final msg = msgs[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withAlpha(25)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(38),
                      child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary, size: 20),
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
                              fontSize: 12,
                            ),
                      ),
                    ),
                    trailing: msg.processed
                        ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                        : const Icon(Icons.pending, color: AppTheme.warning, size: 20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message: ${msg.text}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
