import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../services/haptics/astra_haptics.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system/astra_3d_button.dart';

// ─── Step index constants ─────────────────────────────────────────────────────

const int _kStepAllSet = 3;
const int _kTotalSteps = 4;

// ─── OnboardingScreen ─────────────────────────────────────────────────────────

/// Multi-step first-run setup screen.
///
/// Routing rules (enforced by main.dart):
///   - Shown only when hasSeenOnboarding == false.
///   - hasSeenOnboarding is written only upon completing Step 4 (ALL SET).
///   - An interrupted run safely restarts from Step 1.
///
/// Permission architecture:
///   - POST_NOTIFICATIONS and SCHEDULE_EXACT_ALARM are treated as independent.
///   - Each has its own step with a dedicated rationale.
///   - State is re-read after returning from Android Settings (AppLifecycleListener).
///   - Google / Calendar permissions are NOT requested here — context-gated later.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Permission tracking ──────────────────────────────────────────────────
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;

  // true while we're waiting for requestNotificationPermission() / requestExactAlarmPermission()
  bool _permissionPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  /// Called when app resumes from Android Settings — re-check actual state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionState();
    }
  }

  Future<void> _refreshPermissionState() async {
    final readiness = await NotificationService.checkReminderReadiness();
    if (!mounted) return;
    setState(() {
      switch (readiness) {
        case ReminderReadinessState.ready:
          _notificationGranted = true;
          _exactAlarmGranted = true;
        case ReminderReadinessState.exactAlarmPermissionRequired:
          _notificationGranted = true;
          _exactAlarmGranted = false;
        case ReminderReadinessState.notificationPermissionRequired:
        case ReminderReadinessState.restricted:
        case ReminderReadinessState.unknown:
          _notificationGranted = false;
          _exactAlarmGranted = false;
      }
    });
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _advance() {
    AstraHaptics.selection();
    if (_currentStep < _kTotalSteps - 1) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// "SKIP SETUP" — mark complete, go directly to auth/home without requesting
  /// any permissions. User can enable them later from Settings.
  Future<void> _skipSetup() async {
    AstraHaptics.light();
    await _finishOnboarding();
  }

  /// Called by LET'S GO on Step 4.
  Future<void> _letSGo() async {
    AstraHaptics.medium();
    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    // Write hasSeenOnboarding only at this point — kills/restarts before here
    // safely restart onboarding from the top.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    // If user is already authenticated (e.g. returning from a reinstall that
    // preserved preferences), go Home. Otherwise go to Auth where they can
    // sign in or continue locally.
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    final prefs2 = await SharedPreferences.getInstance();
    final hasSeenAuth = prefs2.getBool('hasSeenAuth') ?? false;

    if (!mounted) return;
    if (isAuthenticated || hasSeenAuth) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  // ── Permission actions ───────────────────────────────────────────────────

  Future<void> _requestNotificationPermission() async {
    AstraHaptics.medium();
    setState(() => _permissionPending = true);
    try {
      final granted = await NotificationService.requestNotificationPermission();
      if (!mounted) return;
      setState(() {
        _notificationGranted = granted;
        _permissionPending = false;
      });
      // Advance regardless — onboarding must never block on a denied permission.
      _advance();
    } catch (_) {
      if (!mounted) return;
      setState(() => _permissionPending = false);
      _advance();
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    AstraHaptics.medium();
    setState(() => _permissionPending = true);
    try {
      // This opens Android Settings (SCHEDULE_EXACT_ALARM). The result is
      // read when the app resumes via didChangeAppLifecycleState.
      await NotificationService.requestExactAlarmPermission();
      if (!mounted) return;
      setState(() => _permissionPending = false);
      // Don't advance yet — wait for user to return from Settings.
      // _refreshPermissionState() will update the UI; user taps Continue.
    } catch (_) {
      if (!mounted) return;
      setState(() => _permissionPending = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AstraColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: dot indicator + SKIP SETUP ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Dot indicator
                  Row(
                    children: List.generate(_kTotalSteps, (i) {
                      final isActive = i == _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 5),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AstraColors.lime
                              : AstraColors.surface3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // SKIP SETUP — always visible except on step 4
                  if (_currentStep < _kStepAllSet)
                    TextButton(
                      onPressed: _skipSetup,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'SKIP SETUP',
                        style: TextStyle(
                          color: AstraColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Page content ────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                // Allow swipe — user can browse steps freely; code also drives navigation.
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _WelcomePage(onGetStarted: _advance),
                  _NotificationsPage(
                    granted: _notificationGranted,
                    isPending: _permissionPending,
                    onEnable: _requestNotificationPermission,
                    onSkip: _advance,
                  ),
                  _PreciseRemindersPage(
                    notificationGranted: _notificationGranted,
                    exactAlarmGranted: _exactAlarmGranted,
                    isPending: _permissionPending,
                    onEnable: _requestExactAlarmPermission,
                    onContinue: _advance,
                  ),
                  _AllSetPage(
                    notificationGranted: _notificationGranted,
                    exactAlarmGranted: _exactAlarmGranted,
                    onLetsGo: _letSGo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _WelcomePage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AstraDepthColors.darkFace,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AstraDepthColors.darkBorder),
              boxShadow: const [
                BoxShadow(
                  color: AstraDepthColors.darkDepth,
                  blurRadius: 0,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 38,
              color: AstraColors.lime,
            ),
          ),
          const SizedBox(height: 28),

          // Wordmark
          Text(
            'ASTRA',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AstraColors.text,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your AI Life Scheduler',
            style: TextStyle(
              fontSize: 15,
              color: AstraColors.textMuted,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 32),

          // Tagline
          const Text(
            'Let\'s set a few things up.\nIt takes under a minute.',
            style: TextStyle(
              fontSize: 17,
              color: AstraColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.55,
            ),
          ),

          const Spacer(flex: 2),

          // CTA
          Astra3DButton(
            key: const Key('onboarding_get_started_button'),
            expand: true,
            height: 56,
            palette: AstraMaterials.lime,
            label: 'GET STARTED',
            onTap: onGetStarted,
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── Step 2: Notifications ────────────────────────────────────────────────────

class _NotificationsPage extends StatelessWidget {
  final bool granted;
  final bool isPending;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const _NotificationsPage({
    required this.granted,
    required this.isPending,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          // Icon block
          _OnboardingIconBlock(
            icon: LucideIcons.bell,
            color: AstraColors.cyan,
            bgColor: const Color(0x1A00E5FF),
            borderColor: const Color(0x4D00E5FF),
          ),
          const SizedBox(height: 24),

          // Labels
          const Text(
            'STAY ON TOP OF THINGS',
            style: TextStyle(
              color: AstraColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable Reminders',
            style: TextStyle(
              color: AstraColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ASTRA can alert you about upcoming tasks right on time. '
            'Without this, time-sensitive reminders won\'t reach you.',
            style: TextStyle(
              color: AstraColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const Spacer(flex: 2),

          // Already granted badge
          if (granted) ...[
            _StatusBadge(
              label: 'Notifications already enabled',
              isGranted: true,
            ),
            const SizedBox(height: 16),
          ],

          // Primary action
          Astra3DButton(
            key: const Key('onboarding_enable_notifications_button'),
            expand: true,
            height: 52,
            palette: granted ? AstraMaterials.dark : AstraMaterials.lime,
            label: granted ? 'CONTINUE →' : 'ENABLE REMINDERS',
            onTap: isPending ? null : (granted ? onSkip : onEnable),
            child: isPending && !granted
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Skip link
          if (!granted)
            Center(
              child: TextButton(
                onPressed: isPending ? null : onSkip,
                child: const Text(
                  'Skip for now →',
                  style: TextStyle(
                    color: AstraColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── Step 3: Precise Reminders ────────────────────────────────────────────────

class _PreciseRemindersPage extends StatelessWidget {
  final bool notificationGranted;
  final bool exactAlarmGranted;
  final bool isPending;
  final VoidCallback onEnable;
  final VoidCallback onContinue;

  const _PreciseRemindersPage({
    required this.notificationGranted,
    required this.exactAlarmGranted,
    required this.isPending,
    required this.onEnable,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Show a contextual note if notifications are denied (independent capability).
    final showNotifWarning = !notificationGranted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          _OnboardingIconBlock(
            icon: LucideIcons.alarmClock,
            color: AstraColors.lime,
            bgColor: const Color(0x1ACEFF00),
            borderColor: const Color(0x4DCEFF00),
          ),
          const SizedBox(height: 24),

          const Text(
            'PRECISE REMINDERS',
            style: TextStyle(
              color: AstraColors.lime,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable Exact Alarm Access',
            style: TextStyle(
              color: AstraColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Android limits when apps can fire alerts. Exact alarm access '
            'lets ASTRA remind you at the precise time you requested '
            '— not minutes later due to battery optimization.',
            style: TextStyle(
              color: AstraColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          // Contextual warning if notifications are also off
          if (showNotifWarning) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x1AF59E0B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x4DF59E0B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.triangleAlert,
                    size: 16,
                    color: AstraColors.amber,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notifications are also off. Enable both for reminders '
                      'to be visible.',
                      style: TextStyle(
                        color: AstraColors.amber,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(flex: 2),

          if (exactAlarmGranted) ...[
            _StatusBadge(
              label: 'Exact alarm access already granted',
              isGranted: true,
            ),
            const SizedBox(height: 16),
          ],

          // Primary action
          Astra3DButton(
            key: const Key('onboarding_enable_exact_alarm_button'),
            expand: true,
            height: 52,
            palette: exactAlarmGranted ? AstraMaterials.dark : AstraMaterials.lime,
            label: exactAlarmGranted ? 'CONTINUE →' : 'ENABLE EXACT ALARMS',
            onTap: isPending ? null : (exactAlarmGranted ? onContinue : onEnable),
            child: isPending && !exactAlarmGranted
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // "Not now" link — advances to Step 4
          if (!exactAlarmGranted)
            Center(
              child: TextButton(
                key: const Key('onboarding_exact_alarm_later_button'),
                onPressed: isPending ? null : onContinue,
                child: const Text(
                  'Not now →',
                  style: TextStyle(
                    color: AstraColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // If opened Settings, show a re-check hint
          if (!exactAlarmGranted && !isPending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Returning from Settings? ASTRA will re-check automatically.',
                  style: const TextStyle(
                    color: AstraColors.textDisabled,
                    fontSize: 11,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── Step 4: ALL SET ──────────────────────────────────────────────────────────

class _AllSetPage extends ConsumerWidget {
  final bool notificationGranted;
  final bool exactAlarmGranted;
  final VoidCallback onLetsGo;

  const _AllSetPage({
    required this.notificationGranted,
    required this.exactAlarmGranted,
    required this.onLetsGo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          // Success icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0x1ACEFF00),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x4DCEFF00)),
            ),
            child: const Icon(
              LucideIcons.checkCheck,
              size: 34,
              color: AstraColors.lime,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'ALL SET',
            style: TextStyle(
              color: AstraColors.lime,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re ready to go',
            style: TextStyle(
              color: AstraColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Status summary
          _PermissionStatusRow(
            label: 'Notifications',
            granted: notificationGranted,
          ),
          const SizedBox(height: 10),
          _PermissionStatusRow(
            label: 'Precise reminders',
            granted: exactAlarmGranted,
          ),

          const SizedBox(height: 12),
          const Text(
            'You can change these any time in ASTRA Settings → Reminders.',
            style: TextStyle(
              color: AstraColors.textDisabled,
              fontSize: 12,
              height: 1.55,
            ),
          ),

          const Spacer(flex: 2),

          // If already authenticated, a single LET'S GO goes Home
          if (isAuthenticated) ...[
            Astra3DButton(
              key: const Key('onboarding_lets_go_button'),
              expand: true,
              height: 52,
              palette: AstraMaterials.lime,
              label: 'LET\'S GO',
              onTap: onLetsGo,
            ),
          ] else ...[
            // Offer Google sign-in OR local continuation
            Astra3DButton(
              key: const Key('onboarding_google_signin_button'),
              expand: true,
              height: 52,
              palette: AstraMaterials.lime,
              onTap: onLetsGo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.g_mobiledata, color: Colors.black, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'SIGN IN WITH GOOGLE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Astra3DButton(
              key: const Key('onboarding_continue_locally_button'),
              expand: true,
              height: 48,
              palette: AstraMaterials.dark,
              onTap: () async {
                AstraHaptics.light();
                // Skip auth entirely — mark local use, go Home
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenOnboarding', true);
                await prefs.setBool('hasSeenAuth', true);
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
              child: const Text(
                'CONTINUE LOCALLY',
                style: TextStyle(
                  color: AstraColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _OnboardingIconBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  const _OnboardingIconBlock({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isGranted;

  const _StatusBadge({required this.label, required this.isGranted});

  @override
  Widget build(BuildContext context) {
    final color = isGranted ? AstraColors.softGreen : AstraColors.textMuted;
    final bg = isGranted ? const Color(0x1A10B981) : AstraColors.surface1;
    final border = isGranted ? const Color(0x4D10B981) : AstraColors.border;
    final icon = isGranted ? LucideIcons.circleCheck : LucideIcons.circleX;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionStatusRow extends StatelessWidget {
  final String label;
  final bool granted;

  const _PermissionStatusRow({required this.label, required this.granted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          granted ? LucideIcons.circleCheck : LucideIcons.circleX,
          size: 16,
          color: granted ? AstraColors.softGreen : AstraColors.textMuted,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: granted ? AstraColors.textPrimary : AstraColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          granted ? 'Enabled' : 'Disabled',
          style: TextStyle(
            color: granted ? AstraColors.softGreen : AstraColors.textDisabled,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
