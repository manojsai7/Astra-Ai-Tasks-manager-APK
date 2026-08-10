import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/services/google_auth_service.dart';
import '../../domain/services/ai_life_scheduler_service.dart';

/// Interactive UI card for Google OAuth Authentication and Gmail/Calendar Sync.
class GoogleSyncCard extends StatefulWidget {
  final AiLifeSchedulerService schedulerService;
  final VoidCallback? onSyncCompleted;

  const GoogleSyncCard({
    super.key,
    required this.schedulerService,
    this.onSyncCompleted,
  });

  @override
  State<GoogleSyncCard> createState() => _GoogleSyncCardState();
}

class _GoogleSyncCardState extends State<GoogleSyncCard> {
  final GoogleAuthService _authService = GoogleAuthService.instance;
  bool _isSyncing = false;
  bool _isSigningIn = false;
  SchedulerSyncResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _authService.signInSilently().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final account = await _authService.signIn();
      if (account != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${account.email}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _handleSyncNow() async {
    if (!_authService.isSignedIn) {
      await _handleGoogleSignIn();
      if (!_authService.isSignedIn) return;
    }

    setState(() {
      _isSyncing = true;
      _lastResult = null;
    });

    final result = await widget.schedulerService.syncAll();

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastResult = result;
      });

      widget.onSyncCompleted?.call();

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result.totalSynced} items! (${result.applicationsFound} applications, ${result.examsFound} exams)',
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Sync failed'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _authService.currentUser;
    final isSignedIn = _authService.isSignedIn;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Life Scheduler',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isSignedIn
                            ? 'Connected to ${user?.email}'
                            : 'Connect Gmail & Calendar to auto-pull tasks',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSignedIn)
                  TextButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isSignedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                  icon: _isSigningIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.globe, size: 18),
                  label: const Text('Connect Google Account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSyncing ? null : _handleSyncNow,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text(_isSyncing ? 'Syncing Gmail & Calendar...' : 'Sync Gmail & Calendar Now'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (_lastResult != null && _lastResult!.isSuccess) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade400.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Synced ${_lastResult!.totalSynced} items (${_lastResult!.applicationsFound} applications, ${_lastResult!.examsFound} exams)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
