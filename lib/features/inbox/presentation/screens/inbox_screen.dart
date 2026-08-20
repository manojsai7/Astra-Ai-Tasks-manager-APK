import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../features/scheduler/data/services/gmail_sync_service.dart';
import '../../../../models/task_intent.dart';
import '../../../../providers/assistant_provider.dart';
import '../../../../providers/astra_command_executor_provider.dart';
import '../../../../providers/google_calendar_writer_provider.dart';
import '../../../../providers/reminder_provider.dart';
import '../../../../services/haptics/astra_haptics.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/design_system/astra_3d_button.dart';
import '../../../notes/data/repositories/astra_note_repository.dart';
import '../../../notes/domain/models/astra_note.dart';

final inboxEmailsProvider = FutureProvider.autoDispose<List<GmailMessageData>>((ref) async {
  final authService = ref.read(googleAuthServiceProvider);
  final client = await authService.getAuthenticatedClient();
  if (client == null) return const [];
  final gmailService = ref.read(gmailSyncServiceProvider);
  return await gmailService.fetchRelevantEmails(client, maxResults: 20);
});

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String? _statusMessage;
  bool _isSuccessMessage = true;

  Future<void> _handleCreateTaskFromEmail(GmailMessageData msg) async {
    AstraHaptics.medium();
    final intent = TaskIntent(
      title: msg.subject.isNotEmpty ? msg.subject : 'Email Task',
      description: 'From: ${msg.sender}\n\n${msg.snippet}',
      source: 'gmail',
    );

    final executor = ref.read(astraCommandExecutorProvider);
    final result = await executor.executeTaskIntent(
      ref: ref,
      intent: intent,
    );

    setState(() {
      _statusMessage = 'Task Created! "${result.title}"';
      _isSuccessMessage = true;
    });
  }

  Future<void> _handleRemindFromEmail(GmailMessageData msg) async {
    AstraHaptics.medium();
    final now = DateTime.now();
    final scheduledAt = now.add(const Duration(hours: 3));

    final reminderService = ref.read(reminderServiceProvider);
    await reminderService.scheduleReminder(
      taskId: msg.id,
      taskTitle: 'Email: ${msg.subject}',
      scheduledAt: scheduledAt,
    );

    setState(() {
      _statusMessage = 'Reminder set for 3 hours from now!';
      _isSuccessMessage = true;
    });
  }

  Future<void> _handleAddToCalendar(GmailMessageData msg) async {
    AstraHaptics.medium();
    final client = await ref.read(googleAuthServiceProvider).getAuthenticatedClient();
    if (client == null) {
      setState(() {
        _statusMessage = 'Google Sign-In required for Google Calendar sync.';
        _isSuccessMessage = false;
      });
      return;
    }

    try {
      final writer = ref.read(googleCalendarWriterServiceProvider);
      final now = DateTime.now().add(const Duration(days: 1));

      await writer.createEvent(
        client,
        title: msg.subject.isNotEmpty ? msg.subject : 'Email Follow-up',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        description: 'Sender: ${msg.sender}\n${msg.snippet}',
      );

      setState(() {
        _statusMessage = 'Added to Google Calendar!';
        _isSuccessMessage = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Calendar Error: $e';
        _isSuccessMessage = false;
      });
    }
  }

  Future<void> _handleSaveToNotes(GmailMessageData msg) async {
    AstraHaptics.medium();
    final newNote = AstraNote.create(
      title: 'Email: ${msg.subject}',
      body: 'From: ${msg.sender}\nDate: ${DateFormat('yyyy-MM-dd HH:mm').format(msg.date)}\n\n${msg.snippet}',
      tags: ['Email'],
      organization: 'Inbox',
    );

    await ref.read(noteNotifierProvider.notifier).createNote(newNote);

    setState(() {
      _statusMessage = 'Saved to Notes!';
      _isSuccessMessage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final emailsAsync = ref.watch(inboxEmailsProvider);

    return Scaffold(
      backgroundColor: AstraColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASTRA', style: AstraText.label(size: 11, color: AstraColors.cyan)),
                      const SizedBox(height: 2),
                      Text('INBOX', style: AstraText.displayL(size: 32)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: AstraColors.lime, size: 20),
                    onPressed: () => ref.refresh(inboxEmailsProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            if (_statusMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isSuccessMessage ? const Color(0x1ACEFF00) : AstraColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isSuccessMessage ? AstraColors.lime : AstraColors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccessMessage ? LucideIcons.circleCheck : LucideIcons.circleX,
                        size: 14,
                        color: _isSuccessMessage ? AstraColors.lime : AstraColors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(fontSize: 11.5, color: _isSuccessMessage ? AstraColors.lime : AstraColors.red),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _statusMessage = null),
                        child: const Icon(LucideIcons.x, size: 12, color: AstraColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Expanded(
              child: emailsAsync.when(
                data: (emails) {
                  if (emails.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.inbox, size: 36, color: AstraColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('No recent emails in Inbox', style: TextStyle(fontSize: 14, color: AstraColors.textSecondary)),
                          const SizedBox(height: 4),
                          const Text('Connect Google Account or tap refresh above', style: TextStyle(fontSize: 11, color: AstraColors.textMuted)),
                          const SizedBox(height: 16),
                          Astra3DButton(
                            label: 'Refresh Inbox',
                            palette: AstraMaterials.lime,
                            height: 40,
                            onPressed: () => ref.refresh(inboxEmailsProvider),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: emails.length,
                    itemBuilder: (context, index) {
                      final email = emails[index];
                      final formattedDate = DateFormat('MMM d, h:mm a').format(email.date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AstraColors.surface0,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AstraColors.edgeSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    email.sender,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.cyan),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 10, color: AstraColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email.subject,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AstraColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email.snippet,
                              style: const TextStyle(fontSize: 12, color: AstraColors.textSecondary, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            // Quick Action Buttons
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _ActionChip(
                                    label: 'Create Task',
                                    icon: LucideIcons.checkSquare,
                                    color: AstraColors.lime,
                                    onTap: () => _handleCreateTaskFromEmail(email),
                                  ),
                                  const SizedBox(width: 6),
                                  _ActionChip(
                                    label: 'Remind Me',
                                    icon: LucideIcons.bell,
                                    color: AstraColors.cyan,
                                    onTap: () => _handleRemindFromEmail(email),
                                  ),
                                  const SizedBox(width: 6),
                                  _ActionChip(
                                    label: 'Add Calendar',
                                    icon: LucideIcons.calendar,
                                    color: AstraColors.softGreen,
                                    onTap: () => _handleAddToCalendar(email),
                                  ),
                                  const SizedBox(width: 6),
                                  _ActionChip(
                                    label: 'Save Note',
                                    icon: LucideIcons.fileText,
                                    color: AstraColors.textSecondary,
                                    onTap: () => _handleSaveToNotes(email),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AstraColors.lime, strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AstraColors.amber, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Couldn\'t fetch inbox emails',
                          style: AstraText.body(size: 14, color: AstraColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make sure Google Sign-In is active or tap retry',
                          style: AstraText.caption(size: 11, color: AstraColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Astra3DButton(
                          label: 'Retry Fetch',
                          palette: AstraMaterials.lime,
                          height: 40,
                          onPressed: () => ref.refresh(inboxEmailsProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
