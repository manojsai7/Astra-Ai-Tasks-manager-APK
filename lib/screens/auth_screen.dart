import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo / App Icon with Glow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.s32),
                Text(
                  'ASTRA',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        color: AppTheme.textPrimary,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: AppTheme.s8),
                Text(
                  'Your AI Life Scheduler',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const Spacer(),
                // Sign‑In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await HapticFeedback.lightImpact();
                            final success = await notifier.signInWithGoogle();
                            if (success && context.mounted) {
                              Navigator.of(context).pushReplacementNamed('/home');
                            }
                          },
                    icon: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                    label: Text(
                      authState.isLoading ? 'Signing in...' : 'Sign in with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.r16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.s16),
                // Skip Button for quick testing or offline use
                TextButton(
                  onPressed: () async {
                    await HapticFeedback.selectionClick();
                    await notifier.skipOrBypassAuth();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (authState.error != null) ...[
                  const SizedBox(height: AppTheme.s16),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.s12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.s32),
                Text(
                  '🔐 We request access to your Gmail & Calendar\nto automatically schedule tasks & sync events.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.s16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
