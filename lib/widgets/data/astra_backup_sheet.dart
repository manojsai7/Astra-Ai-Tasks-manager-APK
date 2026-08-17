import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/astra_backup_provider.dart';
import '../../services/data/astra_backup_service.dart';
import '../../services/data/astra_crypto_service.dart';
import '../../services/data/astra_restore_service.dart';
import '../../theme/app_theme.dart';
import '../design_system/astra_3d_button.dart';
import '../design_system/astra_card.dart';

/// Bottom sheet for ASTRA portable encrypted database backup and restore operations.
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

  Future<String?> _showCreatePasswordDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscurePass = true;
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AstraColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AstraColors.edgeSoft),
            ),
            title: Row(
              children: [
                const Icon(LucideIcons.lock, color: AstraColors.lime, size: 20),
                const SizedBox(width: 8),
                Text('Create Backup Password', style: AstraText.displayM(size: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set a password to encrypt your ASTRA backup (AES-256-GCM).',
                    style: TextStyle(fontSize: 12, color: AstraColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AstraColors.lime.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AstraColors.lime.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.shieldAlert, size: 16, color: AstraColors.lime),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keep this password safe. ASTRA cannot recover your data without it.',
                            style: TextStyle(fontSize: 11, color: Colors.lime.shade200, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    autofocus: true,
                    style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Backup Password',
                      labelStyle: const TextStyle(color: AstraColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AstraColors.textMuted),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: obscurePass,
                    style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: const TextStyle(color: AstraColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: AstraColors.red, fontSize: 11)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('CANCEL', style: TextStyle(color: AstraColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AstraColors.lime,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final pass = passCtrl.text.trim();
                  final confirm = confirmCtrl.text.trim();
                  if (pass.isEmpty) {
                    setDialogState(() => errorText = 'Password cannot be empty.');
                    return;
                  }
                  if (pass.length < 4) {
                    setDialogState(() => errorText = 'Password must be at least 4 characters.');
                    return;
                  }
                  if (pass != confirm) {
                    setDialogState(() => errorText = 'Passwords do not match.');
                    return;
                  }
                  Navigator.pop(ctx, pass);
                },
                child: const Text('ENCRYPT & SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _showEnterPasswordDialog(AstraBackupMetadata metadata, String fileName) async {
    final passCtrl = TextEditingController();
    bool obscurePass = true;
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AstraColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AstraColors.edgeSoft),
            ),
            title: Row(
              children: [
                const Icon(LucideIcons.keyRound, color: AstraColors.lime, size: 20),
                const SizedBox(width: 8),
                Text('Decrypt ASTRA Backup', style: AstraText.displayM(size: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archive: $fileName',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.lime),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow('Created:', DateFormat('MMM d, yyyy · h:mm a').format(metadata.createdAt.toLocal())),
                  _DetailRow('App Version:', metadata.appVersion),
                  _DetailRow('Tasks:', '${metadata.taskCount}'),
                  _DetailRow('Messages:', '${metadata.messageCount}'),
                  _DetailRow('Memories:', '${metadata.memoryCount}'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    autofocus: true,
                    style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Enter Backup Password',
                      labelStyle: const TextStyle(color: AstraColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AstraColors.textMuted),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: AstraColors.red, fontSize: 11)),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ Restoring will replace current local tasks, messages, and memories with the archive contents.',
                    style: TextStyle(fontSize: 11, color: AstraColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('CANCEL', style: TextStyle(color: AstraColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AstraColors.lime,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final pass = passCtrl.text.trim();
                  if (pass.isEmpty) {
                    setDialogState(() => errorText = 'Password cannot be empty.');
                    return;
                  }
                  Navigator.pop(ctx, pass);
                },
                child: const Text('DECRYPT & RESTORE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleBackup() async {
    final password = await _showCreatePasswordDialog();
    if (password == null) return; // User cancelled password setup

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final backupService = ref.read(astraBackupServiceProvider);
      final storageService = ref.read(astraBackupStorageServiceProvider);

      // Create AES-256-GCM encrypted V2 backup package
      final payload = await backupService.createEncryptedBackup(password: password);
      final bytes = payload.toBytes();
      final fileName = AstraBackupService.generateBackupFileName();

      // Save via Android Storage Access Framework (SAF ACTION_CREATE_DOCUMENT)
      final savedPath = await storageService.saveBackupDocument(
        fileName: fileName,
        bytes: bytes,
      );

      if (!mounted) return;

      if (savedPath != null && savedPath.isNotEmpty) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _statusMessage = 'Encrypted backup saved successfully:\n$fileName\n($savedPath)';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _statusMessage = 'Encrypted backup created: $fileName';
        });
      }

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
      final storageService = ref.read(astraBackupStorageServiceProvider);
      final restoreService = ref.read(astraRestoreServiceProvider);

      // Open Android Storage Access Framework (SAF ACTION_OPEN_DOCUMENT)
      final pickedDoc = await storageService.pickBackupDocument();

      if (pickedDoc == null) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        return;
      }

      // Validate envelope structure and schema version
      final metadata = restoreService.validateBackup(pickedDoc.bytes);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      String? password;
      if (metadata.isEncryptedV2) {
        password = await _showEnterPasswordDialog(metadata, pickedDoc.name);
        if (password == null) return; // User cancelled password dialog
      } else {
        // Legacy V1 plaintext preview confirmation
        final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AstraColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AstraColors.edgeSoft),
            ),
            title: Text('Restore Legacy Backup?', style: AstraText.displayM(size: 20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archive: ${pickedDoc.name}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.lime),
                ),
                const SizedBox(height: 10),
                _DetailRow('Created:', DateFormat('MMM d, yyyy · h:mm a').format(metadata.createdAt.toLocal())),
                _DetailRow('App Version:', metadata.appVersion),
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
      }

      setState(() => _isProcessing = true);
      final result = await executeAstraRestore(
        ref,
        pickedDoc.bytes,
        password: password,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Restored ${result.tasksRestored} tasks, ${result.messagesRestored} messages, and ${result.memoriesRestored} memories.';
      });
    } on AstraCryptoException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Decryption failed: ${e.message}';
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
                const Icon(LucideIcons.shieldCheck, color: AstraColors.lime, size: 24),
                const SizedBox(width: 10),
                Text('DATA & ENCRYPTED BACKUP', style: AstraText.displayM(size: 20)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '100% on-device SQLite database with AES-256-GCM password-encrypted backups.',
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
                    icon: LucideIcons.lock,
                    palette: AstraMaterials.lime,
                    height: 48,
                    onTap: _isProcessing ? null : _handleBackup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Astra3DButton(
                    label: 'RESTORE DATA',
                    icon: LucideIcons.keyRound,
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
