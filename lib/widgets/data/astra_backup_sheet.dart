import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/astra_backup_provider.dart';
import '../../services/data/astra_backup_service.dart';
import '../../services/data/astra_restore_service.dart';
import '../../theme/app_theme.dart';
import '../design_system/astra_3d_button.dart';
import '../design_system/astra_card.dart';

/// Bottom sheet for ASTRA local database backup and restore operations.
class AstraBackupSheet extends ConsumerStatefulWidget {
  const AstraBackupSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AstraColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AstraBackupSheet(),
    );
  }

  @override
  ConsumerState<AstraBackupSheet> createState() => _AstraBackupSheetState();
}

class _AstraBackupSheetState extends ConsumerState<AstraBackupSheet> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = true;

  Future<void> _handleBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final backupService = ref.read(astraBackupServiceProvider);
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();
      final fileName = AstraBackupService.generateBackupFileName();

      // Write to application documents directory
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final file = File('${backupDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Backup saved successfully:\n$fileName\n(${file.path})';
      });
      ref.invalidate(databaseStatsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Backup failed: $e';
      });
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');

      if (!await backupDir.exists()) {
        setState(() {
          _isProcessing = false;
          _isSuccess = false;
          _statusMessage = 'No local backups found in ${backupDir.path}.';
        });
        return;
      }

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.astra.db'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (files.isEmpty) {
        setState(() {
          _isProcessing = false;
          _isSuccess = false;
          _statusMessage = 'No .astra.db files found in backup directory.';
        });
        return;
      }

      final latestFile = files.first;
      final bytes = await latestFile.readAsBytes();

      final restoreService = ref.read(astraRestoreServiceProvider);
      final metadata = restoreService.validateBackup(bytes);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AstraColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AstraColors.edgeSoft),
          ),
          title: Text('Restore ASTRA Data?', style: AstraText.displayM(size: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archive: ${latestFile.uri.pathSegments.last}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.lime),
              ),
              const SizedBox(height: 10),
              _DetailRow('Created:', DateFormat('MMM d, yyyy · h:mm a').format(metadata.createdAt.toLocal())),
              _DetailRow('App Version:', metadata.appVersion),
              _DetailRow('Schema Version:', 'v${metadata.schemaVersion}'),
              _DetailRow('Tasks:', '${metadata.taskCount}'),
              _DetailRow('Messages:', '${metadata.messageCount}'),
              _DetailRow('Memories:', '${metadata.memoryCount}'),
              const SizedBox(height: 14),
              const Text(
                '⚠️ This will replace current local tasks, messages, and memories with the archive contents.',
                style: TextStyle(fontSize: 11, color: AstraColors.textMuted, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL', style: TextStyle(color: AstraColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AstraColors.lime,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('RESTORE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldRestore != true) return;

      setState(() => _isProcessing = true);
      final result = await executeAstraRestore(ref, bytes);

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Restored ${result.tasksRestored} tasks, ${result.messagesRestored} messages, and ${result.memoriesRestored} memories.';
      });
    } on AstraRestoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Restore validation error: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Restore error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(databaseStatsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.database, color: AstraColors.lime, size: 24),
                const SizedBox(width: 10),
                Text('DATA & PRIVACY', style: AstraText.displayM(size: 22)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '100% on-device SQLite database. No cloud DB or tracking.',
              style: AstraText.body(size: 13, color: AstraColors.textMuted),
            ),
            const SizedBox(height: 18),

            // Live Database Stats Card
            AstraCard(
              padding: const EdgeInsets.all(16),
              child: statsAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ASTRA LOCAL DATA', style: AstraText.label(size: 11, color: AstraColors.textPrimary)),
                        Text(stats.formattedSize, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.lime)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatPill(label: 'TASKS', value: '${stats.taskCount}'),
                        _StatPill(label: 'MESSAGES', value: '${stats.messageCount}'),
                        _StatPill(label: 'MEMORIES', value: '${stats.memoryCount}'),
                        _StatPill(label: 'ALARMS', value: '${stats.reminderCount}'),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading stats: $e', style: const TextStyle(color: AstraColors.red)),
              ),
            ),
            const SizedBox(height: 20),

            // Status message banner
            if (_statusMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? AstraColors.lime.withValues(alpha: 0.1) : AstraColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSuccess ? AstraColors.lime : AstraColors.red),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSuccess ? AstraColors.lime : AstraColors.red,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Astra3DButton(
                    label: _isProcessing ? 'Working…' : 'BACK UP NOW',
                    icon: LucideIcons.downloadCloud,
                    palette: AstraMaterials.lime,
                    height: 48,
                    onTap: _isProcessing ? null : _handleBackup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Astra3DButton(
                    label: 'RESTORE DATA',
                    icon: LucideIcons.uploadCloud,
                    palette: AstraMaterials.neutral,
                    height: 48,
                    onTap: _isProcessing ? null : _handleRestore,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AstraColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AstraColors.textMuted, letterSpacing: 0.5)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AstraColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AstraColors.textPrimary)),
        ],
      ),
    );
  }
}
