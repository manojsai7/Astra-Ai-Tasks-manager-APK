import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/haptics/astra_haptics.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

/// Compact reminder readiness banner shown in HomeScreen when
/// POST_NOTIFICATIONS or SCHEDULE_EXACT_ALARM permissions are missing.
///
/// - Mounts as a `StatefulWidget` so it re-checks readiness on each build.
/// - Dismissed per-session (not persisted) so it reappears next launch until fixed.
/// - Tapping the action button opens the relevant system settings.
class AstraReminderReadinessBanner extends StatefulWidget {
  const AstraReminderReadinessBanner({super.key});

  @override
  State<AstraReminderReadinessBanner> createState() =>
      _AstraReminderReadinessBannerState();
}

class _AstraReminderReadinessBannerState
    extends State<AstraReminderReadinessBanner> with WidgetsBindingObserver {
  ReminderReadinessState _state = ReminderReadinessState.ready;
  bool _dismissed = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check when returning from Android Settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_dismissed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    final result = await NotificationService.checkReminderReadiness();
    if (mounted) {
      setState(() {
        _state = result;
        _checking = false;
      });
    }
  }

  Future<void> _onActionTap() async {
    AstraHaptics.medium();
    switch (_state) {
      case ReminderReadinessState.notificationPermissionRequired:
        await NotificationService.requestNotificationPermission();
      case ReminderReadinessState.exactAlarmPermissionRequired:
        await NotificationService.requestExactAlarmPermission();
      default:
        break;
    }
    // Re-check on resume via WidgetsBindingObserver.
  }

  @override
  Widget build(BuildContext context) {
    // Ready or dismissed: render nothing.
    if (_dismissed || _state == ReminderReadinessState.ready) {
      return const SizedBox.shrink();
    }

    final String label;
    final String action;
    final IconData icon;

    switch (_state) {
      case ReminderReadinessState.notificationPermissionRequired:
        label = 'Notifications are off — reminders won\'t reach you.';
        action = 'ENABLE';
        icon = LucideIcons.bellOff;
      case ReminderReadinessState.exactAlarmPermissionRequired:
        label = 'Reminders may be delayed. Enable exact alarm access.';
        action = 'FIX';
        icon = LucideIcons.alarmClock;
      case ReminderReadinessState.restricted:
        label = 'Reminders are restricted by device policy.';
        action = 'SETTINGS';
        icon = LucideIcons.shieldAlert;
      case ReminderReadinessState.ready:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x1AF59E0B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x4DF59E0B)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AstraColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AstraColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Action button
              GestureDetector(
                onTap: _onActionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AstraColors.amber,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Dismiss × for this session
              GestureDetector(
                onTap: () {
                  AstraHaptics.light();
                  setState(() => _dismissed = true);
                },
                child: const Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AstraColors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
