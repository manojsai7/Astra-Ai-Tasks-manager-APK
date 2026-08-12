import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/design_system/astra_3d_button.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: AstraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // ── App identity ─────────────────────────────────────────────
              // Near-black physical icon block — dark face, grey depth
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AstraDepthColors.darkFace,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AstraDepthColors.darkBorder, width: 1),
                  boxShadow: const [
                    // Grey physical underside — the reference back-button aesthetic
                    BoxShadow(
                      color: AstraDepthColors.darkDepth,
                      blurRadius: 0,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 46,
                  color: AstraColors.lime,  // brand lime on charcoal — restrained
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'ASTRA',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: AstraColors.text,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI Life Scheduler',
                style: TextStyle(
                  fontSize: 15,
                  color: AstraColors.textMuted,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(),

              // ── Primary action: lime physical ────────────────────────────
              Astra3DButton(
                expand: true,
                height: 56,
                depth: AstraDepth.medium,
                palette: AstraMaterials.lime,
                onTap: authState.isLoading
                    ? null
                    : () async {
                        await HapticFeedback.lightImpact();
                        final success = await notifier.signInWithGoogle();
                        if (success && context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      },
                child: authState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.g_mobiledata, color: Colors.black, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'SIGN IN WITH GOOGLE',
                            style: AstraText.label(
                              color: Colors.black,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              // ── Secondary action: dark physical (grey underside) ─────────
              Astra3DButton(
                expand: true,
                height: 50,
                depth: AstraDepth.small,
                palette: AstraMaterials.dark,
                onTap: () async {
                  await HapticFeedback.selectionClick();
                  await notifier.skipOrBypassAuth();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                },
                child: Text(
                  'CONTINUE AS GUEST',
                  style: AstraText.label(
                    color: AstraColors.textMuted,
                    size: 11,
                  ),
                ),
              ),

              // ── Error state: charcoal card + red left strip ──────────────
              if (authState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AstraColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AstraColors.edgeSoft, width: 1),
                    boxShadow: const [
                      BoxShadow(color: AstraColors.depth, offset: Offset(0, 3), blurRadius: 0),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Row(
                      children: [
                        // Red semantic strip
                        Container(
                          width: 3,
                          height: 48,
                          color: AstraColors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              authState.error!,
                              style: const TextStyle(
                                color: AstraColors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Legal disclaimer ─────────────────────────────────────────
              Text(
                '🔐 We request access to your Gmail & Calendar\nto automatically schedule tasks & sync events.',
                style: TextStyle(
                  color: AstraColors.textMuted,
                  fontSize: 11,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
