import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/haptics/astra_haptics.dart';
import '../../providers/astra_backup_provider.dart';
import '../../services/data/astra_backup_service.dart';
import '../../services/data/astra_crypto_service.dart';
import '../../services/data/astra_restore_service.dart';
import '../../theme/app_theme.dart';
import '../design_system/astra_3d_button.dart';
import '../design_system/astra_card.dart';

/// Password strength level for advisory UI indication.
enum PasswordStrength {
  weak('Weak', AstraColors.red, 0.33),
  fair('Fair', AstraColors.amber, 0.66),
  strong('Strong', AstraColors.lime, 1.0);

  final String label;
  final Color color;
  final double fraction;

  const PasswordStrength(this.label, this.color, this.fraction);

  static PasswordStrength evaluate(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    final hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[^a-zA-Z0-9]'));

    if (password.length >= 10 && hasLetters && hasNumbers && hasSpecial) {
      return PasswordStrength.strong;
    }
    if (password.length >= 6 && ((hasLetters && hasNumbers) || hasSpecial)) {
      return PasswordStrength.fair;
    }
    return PasswordStrength.weak;
  }
}

/// Bottom sheet for ASTRA portable encrypted database backup, selective export, and restore operations.
class AstraBackupSheet extends ConsumerStatefulWidget {
  const AstraBackupSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AstraColors.surface0,
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
  final Set<AstraBackupCategory> _selectedCategories = Set.from(AstraBackupCategory.defaultCategories);

  void _selectAll() {
    AstraHaptics.selection();
    setState(() {
      _selectedCategories.addAll(AstraBackupCategory.values);
    });
  }

  void _selectNone() {
    AstraHaptics.selection();
    setState(() {
      _selectedCategories.clear();
    });
  }

  void _toggleCategory(AstraBackupCategory category) {
    AstraHaptics.selection();
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<String?> _showCreatePasswordDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscurePass = true;
    String? errorText;
    PasswordStrength strength = PasswordStrength.weak;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AstraColors.surface1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AstraColors.borderSubtle),
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
                    'Set a password to encrypt your ASTRA backup (AES-256-GCM + PBKDF2).',
                    style: TextStyle(fontSize: 12, color: AstraColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x1ACEFF00),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x4DCEFF00)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.shieldAlert, size: 16, color: AstraColors.lime),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Keep this password safe. ASTRA cannot recover your data without it.',
                            style: TextStyle(fontSize: 11, color: AstraColors.textPrimary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password Field
                  TextField(
                    key: const Key('backup_password_field'),
                    controller: passCtrl,
                    obscureText: obscurePass,
                    autofocus: true,
                    style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                    onChanged: (val) {
                      setDialogState(() {
                        strength = PasswordStrength.evaluate(val);
                        errorText = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Backup Password',
                      labelStyle: const TextStyle(color: AstraColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AstraColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AstraColors.textMuted),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Advisory Strength Indicator (Non-blocking)
                  if (passCtrl.text.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: strength.fraction,
                              backgroundColor: AstraColors.surface2,
                              valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strength.label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: strength.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Confirm Field
                  TextField(
                    key: const Key('backup_confirm_password_field'),
                    controller: confirmCtrl,
                    obscureText: obscurePass,
                    style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: const TextStyle(color: AstraColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AstraColors.surface2,
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
                key: const Key('backup_encrypt_and_save_button'),
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
            backgroundColor: AstraColors.surface1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AstraColors.borderSubtle),
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
                  _DetailRow('Categories:', metadata.selectedCategories.join(', ')),
                  _DetailRow('Tasks:', '${metadata.taskCount}'),
                  _DetailRow('Messages:', '${metadata.messageCount}'),
                  _DetailRow('Memories:', '${metadata.memoryCount}'),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('restore_password_field'),
                    controller: passCtrl,
                    obscureText: obscurePass,
                    autofocus: true,
                    style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Enter Backup Password',
                      labelStyle: const TextStyle(color: AstraColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AstraColors.surface2,
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('CANCEL', style: TextStyle(color: AstraColors.textMuted)),
              ),
              ElevatedButton(
                key: const Key('restore_decrypt_button'),
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
                child: const Text('DECRYPT & PREVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSelectiveRestoreDialog({
    required AstraBackupMetadata metadata,
    required String fileName,
  }) async {
    final availableCategories = metadata.selectedCategories
        .map((id) => AstraBackupCategory.fromId(id))
        .whereType<AstraBackupCategory>()
        .toSet();

    final categoriesToRestore = Set<AstraBackupCategory>.from(
      availableCategories.isEmpty ? AstraBackupCategory.defaultCategories : availableCategories,
    );

    RestoreStrategy strategy = RestoreStrategy.merge;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AstraColors.surface1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AstraColors.borderSubtle),
            ),
            title: Row(
              children: [
                const Icon(LucideIcons.fileSpreadsheet, color: AstraColors.cyan, size: 20),
                const SizedBox(width: 8),
                Text('RESTORE BACKUP', style: AstraText.displayM(size: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archive: $fileName', style: const TextStyle(fontSize: 11, color: AstraColors.textMuted)),
                  const SizedBox(height: 10),

                  const Text(
                    'Select categories to restore:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  ...availableCategories.map((cat) {
                    final isChecked = categoriesToRestore.contains(cat);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: isChecked,
                      activeColor: AstraColors.lime,
                      title: Text(cat.title, style: const TextStyle(fontSize: 13, color: AstraColors.textPrimary)),
                      subtitle: Text(cat.description, style: const TextStyle(fontSize: 10, color: AstraColors.textMuted)),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            categoriesToRestore.add(cat);
                          } else {
                            categoriesToRestore.remove(cat);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 14),
                  const Text(
                    'Restore Strategy:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.textPrimary),
                  ),
                  const SizedBox(height: 6),

                  GestureDetector(
                    key: const Key('restore_strategy_merge'),
                    onTap: () {
                      AstraHaptics.selection();
                      setDialogState(() => strategy = RestoreStrategy.merge);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: strategy == RestoreStrategy.merge ? const Color(0x1ACEFF00) : AstraColors.surface0,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: strategy == RestoreStrategy.merge ? AstraColors.lime : AstraColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            strategy == RestoreStrategy.merge ? LucideIcons.circleDot : LucideIcons.circle,
                            size: 16,
                            color: strategy == RestoreStrategy.merge ? AstraColors.lime : AstraColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MERGE (Recommended)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.textPrimary),
                                ),
                                Text(
                                  'Preserves newer local edits and combines data.',
                                  style: TextStyle(fontSize: 10, color: AstraColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    key: const Key('restore_strategy_replace'),
                    onTap: () {
                      AstraHaptics.selection();
                      setDialogState(() => strategy = RestoreStrategy.replaceSelected);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: strategy == RestoreStrategy.replaceSelected ? const Color(0x1AFF0055) : AstraColors.surface0,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: strategy == RestoreStrategy.replaceSelected ? AstraColors.red : AstraColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            strategy == RestoreStrategy.replaceSelected ? LucideIcons.circleDot : LucideIcons.circle,
                            size: 16,
                            color: strategy == RestoreStrategy.replaceSelected ? AstraColors.red : AstraColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REPLACE SELECTED DATA',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.red),
                                ),
                                Text(
                                  '⚠️ Replaces local records for chosen categories.',
                                  style: TextStyle(fontSize: 10, color: AstraColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                key: const Key('confirm_restore_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: strategy == RestoreStrategy.replaceSelected ? AstraColors.red : AstraColors.lime,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (categoriesToRestore.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please select at least one category to restore.')),
                    );
                    return;
                  }

                  if (strategy == RestoreStrategy.replaceSelected) {
                    final confirmReplace = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        backgroundColor: AstraColors.surface1,
                        title: const Text('Confirm Replace Data', style: TextStyle(color: AstraColors.red)),
                        content: const Text(
                          'Replace selected ASTRA data?\n\nThis may remove newer local records for the chosen categories.',
                          style: TextStyle(fontSize: 12, color: AstraColors.textPrimary),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AstraColors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('REPLACE'),
                          ),
                        ],
                      ),
                    );
                    if (confirmReplace != true) return;
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx, {
                      'categories': categoriesToRestore,
                      'strategy': strategy,
                    });
                  }
                },
                child: Text(
                  strategy == RestoreStrategy.replaceSelected ? 'REPLACE SELECTED' : 'MERGE DATA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleBackup() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category to back up.')),
      );
      return;
    }

    final password = await _showCreatePasswordDialog();
    if (password == null) return; // User cancelled password setup

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final backupService = ref.read(astraBackupServiceProvider);
      final storageService = ref.read(astraBackupStorageServiceProvider);

      // Create AES-256-GCM encrypted V2 backup package with selected categories
      final payload = await backupService.createEncryptedBackup(
        password: password,
        categories: _selectedCategories,
      );
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
      }

      final restoreOptions = await _showSelectiveRestoreDialog(
        metadata: metadata,
        fileName: pickedDoc.name,
      );
      if (restoreOptions == null) return;

      final chosenCategories = restoreOptions['categories'] as Set<AstraBackupCategory>;
      final chosenStrategy = restoreOptions['strategy'] as RestoreStrategy;

      setState(() => _isProcessing = true);
      final result = await executeAstraRestore(
        ref,
        pickedDoc.bytes,
        password: password,
        strategy: chosenStrategy,
        selectedCategories: chosenCategories,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = 'Restored ${result.tasksRestored} tasks, ${result.messagesRestored} messages, and ${result.memoriesRestored} memories (${chosenStrategy.name}).';
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
        child: SingleChildScrollView(
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
                '100% on-device SQLite with AES-256-GCM encrypted portable backups and automatic Android backup safety.',
                style: AstraText.body(size: 12.5, color: AstraColors.textSecondary),
              ),
              const SizedBox(height: 16),

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
                          Text('ASTRA LOCAL DATA', style: AstraText.label(size: 11, color: AstraColors.cyan)),
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
              const SizedBox(height: 16),

              // Selective Category Checklist Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'WHAT DO YOU WANT TO BACK UP?',
                    style: TextStyle(color: AstraColors.cyan, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _selectAll,
                        child: const Text('Select All', style: TextStyle(color: AstraColors.lime, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _selectNone,
                        child: const Text('Clear', style: TextStyle(color: AstraColors.textMuted, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...AstraBackupCategory.values.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () => _toggleCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AstraColors.surface1 : AstraColors.surface0,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AstraColors.borderSubtle : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AstraColors.lime,
                          onChanged: (_) => _toggleCategory(cat),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AstraColors.textPrimary)),
                              Text(cat.description, style: const TextStyle(fontSize: 10, color: AstraColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Estimated size & category count
              statsAsync.maybeWhen(
                data: (stats) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AstraColors.surface1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedCategories.length} of ${AstraBackupCategory.values.length} categories selected',
                        style: const TextStyle(fontSize: 11, color: AstraColors.textSecondary),
                      ),
                      Text(
                        'Est. size: ${stats.formatBytes(stats.estimateSelectedSize(_selectedCategories))}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AstraColors.cyan),
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Status message banner
              if (_statusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? const Color(0x1ACEFF00) : AstraColors.red.withValues(alpha: 0.1),
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
