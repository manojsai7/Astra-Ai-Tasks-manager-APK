import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../design_system/astra_3d_button.dart';

/// ASTRA-native explanatory sheet for Alarms & Reminders permission access.
class AstraReminderReadinessPrompt extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDismiss;

  const AstraReminderReadinessPrompt({
    super.key,
    this.onGranted,
    this.onDismiss,
  });

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const AstraReminderReadinessPrompt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AstraColors.surface0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AstraColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AstraColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with Alarm Icon
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1A00E5FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x4D00E5FF)),
                ),
                child: const Icon(
                  LucideIcons.alarmClock,
                  size: 20,
                  color: AstraColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRECISE REMINDERS',
                      style: TextStyle(
                        color: AstraColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Enable Exact Alarm Access',
                      style: TextStyle(
                        color: AstraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Explanatory Text
          const Text(
            'ASTRA needs Alarms & reminders access so scheduled reminders can fire as close as possible to the requested time.\n\nWithout this permission, Android may delay reminders by several minutes due to battery optimization.',
            style: TextStyle(
              color: AstraColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              // Secondary "Not now"
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AstraHaptics.light();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(false);
                    }
                    onDismiss?.call();
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AstraColors.surface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AstraColors.border),
                    ),
                    child: const Text(
                      'Not now',
                      style: TextStyle(
                        color: AstraColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Primary "ENABLE"
              Expanded(
                flex: 2,
                child: Astra3DButton(
                  label: 'ENABLE',
                  onPressed: () async {
                    AstraHaptics.medium();
                    final success = await NotificationService.requestExactAlarmPermission();
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(success);
                    }
                    onGranted?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
