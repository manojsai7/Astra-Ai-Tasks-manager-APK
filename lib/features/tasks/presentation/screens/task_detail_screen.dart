import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/database/database.dart';
import '../../domain/entities/task.dart';

/// Full Context Detail View for a Task (showing Company info, Role, Requirements, Links, and Status).
class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final AppDatabase database;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.database,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task.taskType == TaskType.application
              ? 'Application Context'
              : 'Task Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Context details copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<TaskContextEntry?>(
        stream: widget.database.watchTaskContextByTaskId(widget.task.id),
        builder: (context, snapshot) {
          final contextData = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Top Header Card ---
                _buildHeaderCard(context, colorScheme, contextData),

                const SizedBox(height: 16),

                // --- Deadline Alert Box ---
                if (widget.task.dueAt != null)
                  _buildDeadlineCard(context, colorScheme),

                const SizedBox(height: 16),

                // --- Company & Role Card ---
                if (contextData?.companyName != null || contextData?.role != null)
                  _buildCompanyDetailsCard(context, colorScheme, contextData!),

                if (contextData?.companyName != null || contextData?.role != null)
                  const SizedBox(height: 16),

                // --- Requirements Card ---
                if (contextData?.requirements != null && contextData!.requirements!.isNotEmpty)
                  _buildRequirementsCard(context, colorScheme, contextData.requirements!),

                if (contextData?.requirements != null && contextData!.requirements!.isNotEmpty)
                  const SizedBox(height: 16),

                // --- Application Link Card ---
                if (contextData?.applicationLink != null && contextData!.applicationLink!.isNotEmpty)
                  _buildApplicationLinkCard(context, colorScheme, contextData.applicationLink!),

                if (contextData?.applicationLink != null && contextData!.applicationLink!.isNotEmpty)
                  const SizedBox(height: 16),

                // --- Status Card (Mark as Applied) ---
                _buildStatusCard(context, colorScheme, contextData),

                const SizedBox(height: 16),

                // --- Original Context / Email Accordion ---
                if (contextData?.emailSnippet != null || contextData?.fullEmail != null)
                  _buildEmailAccordionCard(context, colorScheme, contextData!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ColorScheme colorScheme, TaskContextEntry? ctx) {
    final typeColor = widget.task.taskType == TaskType.application
        ? Colors.amber.shade700
        : colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.task.taskType.value,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Priority: ${widget.task.priority.value}',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.task.description!,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDeadlineCard(BuildContext context, ColorScheme colorScheme) {
    final due = widget.task.dueAt!;
    final formattedDate = DateFormat('MMMM dd, yyyy – hh:mm a').format(due);
    final daysLeft = due.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: Colors.red.shade400, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deadline: $formattedDate',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysLeft >= 0 ? '$daysLeft days remaining' : 'Deadline passed',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildCompanyDetailsCard(BuildContext context, ColorScheme colorScheme, TaskContextEntry ctx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.building2, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '📋 Company Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (ctx.companyName != null)
              _buildDetailRow(colorScheme, 'Company', ctx.companyName!),
            if (ctx.role != null)
              _buildDetailRow(colorScheme, 'Role', ctx.role!),
            if (ctx.location != null)
              _buildDetailRow(colorScheme, 'Location', ctx.location!),
            if (ctx.stipend != null)
              _buildDetailRow(colorScheme, 'Stipend / CTC', ctx.stipend!),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildDetailRow(ColorScheme colorScheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '• $label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(BuildContext context, ColorScheme colorScheme, String requirements) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.fileText, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '📝 Requirements & Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              requirements,
              style: TextStyle(
                height: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildApplicationLinkCard(BuildContext context, ColorScheme colorScheme, String link) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.link, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '📎 Application Link',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              link,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open link: $link')),
                      );
                    }
                  }
                },
                icon: const Icon(LucideIcons.externalLink, size: 18),
                label: const Text('Apply Now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatusCard(BuildContext context, ColorScheme colorScheme, TaskContextEntry? ctx) {
    final hasApplied = ctx?.hasApplied ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasApplied ? Colors.green.shade400 : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasApplied ? LucideIcons.checkCircle2 : LucideIcons.clock,
                  color: hasApplied ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '📊 Application Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasApplied
                  ? '✅ Applied on ${ctx?.appliedAt != null ? DateFormat('MMM dd, yyyy').format(ctx!.appliedAt!) : "Recently"}'
                  : '⏳ Not applied yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: hasApplied ? Colors.green : Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final newStatus = !hasApplied;
                  await widget.database.updateAppliedStatus(widget.task.id, newStatus);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus ? 'Marked as Applied! 🎉' : 'Marked as Pending',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  hasApplied ? LucideIcons.xCircle : LucideIcons.checkCheck,
                  size: 18,
                ),
                label: Text(hasApplied ? 'Mark as Not Applied' : 'Mark as Applied'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildEmailAccordionCard(BuildContext context, ColorScheme colorScheme, TaskContextEntry ctx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(
          '✉️ Source ${ctx.source == "gmail" ? "Email Context" : "Calendar Context"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          ctx.emailSnippet ?? 'Tap to view original source text',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText(
              ctx.fullEmail ?? ctx.emailSnippet ?? 'No additional text available.',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}
