import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/profile_provider.dart';
import '../providers/assistant_provider.dart';
import '../services/profile/astra_profile_service.dart';
import '../services/haptics/astra_haptics.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/data/astra_backup_sheet.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(astraProfileProvider);

    return Scaffold(
      backgroundColor: AstraColors.background,
      appBar: AppBar(
        backgroundColor: AstraColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(LucideIcons.chevronLeft, color: AstraColors.textPrimary),
        ),
        title: Text('PROFILE & SETTINGS', style: AstraText.label(size: 13, color: AstraColors.textSecondary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ProfileHero(profile: profile),
            const SizedBox(height: 18),
            _Section(
              title: 'ACCOUNT',
              children: [
                _SettingsRow(
                  icon: LucideIcons.userRound,
                  label: 'Nickname',
                  value: profile.nickname.isEmpty ? 'Set your name' : profile.nickname,
                  onTap: () => _editNickname(context, ref, profile.nickname),
                ),
                _SettingsRow(
                  icon: LucideIcons.mail,
                  label: 'Google account',
                  value: profile.email.isEmpty ? 'Not connected' : profile.email,
                  valueColor: profile.email.isEmpty ? AstraColors.textMuted : AstraColors.textSecondary,
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'REMINDERS',
              children: [
                _ReminderReadinessRow(),
                _SettingsRow(
                  icon: LucideIcons.bellRing,
                  label: 'Notifications',
                  value: 'Open Android settings',
                  onTap: NotificationService.requestNotificationPermission,
                ),
                _SettingsRow(
                  icon: LucideIcons.alarmClock,
                  label: 'Precise reminders',
                  value: 'Alarms & reminders',
                  onTap: NotificationService.requestExactAlarmPermission,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'APP EXPERIENCE',
              children: [
                const _SettingsRow(icon: LucideIcons.palette, label: 'Appearance', value: 'ASTRA Graphite', showChevron: false),
                _SettingsRow(
                  icon: LucideIcons.smartphone,
                  label: 'Haptics & motion',
                  value: AstraHaptics.isEnabled ? 'Enabled' : 'Disabled',
                  onTap: () {
                    AstraHaptics.isEnabled = !AstraHaptics.isEnabled;
                    ref.invalidate(astraProfileProvider);
                  },
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'DATA & PRIVACY',
              children: [
                _SettingsRow(
                  icon: LucideIcons.shieldCheck,
                  label: 'Backup & Restore',
                  value: 'Encrypted portable backup',
                  onTap: () => AstraBackupSheet.show(context),
                ),
                const _SettingsRow(icon: LucideIcons.brain, label: 'ASTRA Memory', value: 'Local-first', showChevron: false),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'INTEGRATIONS',
              children: [
                _SettingsRow(
                  icon: LucideIcons.calendarDays,
                  label: 'Google Calendar',
                  value: profile.isGoogleConnected ? 'Connected' : 'Connect when needed',
                  showChevron: false,
                ),
                _SettingsRow(
                  icon: LucideIcons.inbox,
                  label: 'Gmail Inbox',
                  value: profile.isGoogleConnected ? 'Available' : 'Connect when needed',
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'ABOUT ASTRA',
              children: [
                const _SettingsRow(icon: LucideIcons.sparkles, label: "What's new", value: 'Release notes', showChevron: false),
                const _SettingsRow(icon: LucideIcons.info, label: 'Version', value: '2.2.0', showChevron: false),
              ],
            ),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _signOut(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AstraColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AstraColors.red.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.logOut, color: AstraColors.red, size: 19),
                    const SizedBox(width: 12),
                    Text('SIGN OUT', style: AstraText.metric(color: AstraColors.red, size: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNickname(BuildContext context, WidgetRef ref, String existing) async {
    final controller = TextEditingController(text: existing);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AstraColors.surface1,
        title: const Text('What should ASTRA call you?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Your nickname', counterText: ''),
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('SAVE')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await ref.read(astraProfileProvider.notifier).setNickname(value);
    AstraHaptics.success();
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AstraColors.surface1,
        title: const Text('Sign out of ASTRA?'),
        content: const Text('Your local tasks, reminders and memory stay on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('SIGN OUT')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(assistantStateProvider.notifier).handleSignOut();
    await ref.read(astraProfileProvider.notifier).clearGoogleConnection();
    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }
}

class _ProfileHero extends StatelessWidget {
  final AstraProfile profile;
  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AstraColors.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AstraColors.borderSubtle),
        boxShadow: const [BoxShadow(color: AstraColors.depth, offset: Offset(0, 5), blurRadius: 0)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AstraColors.surface3,
            backgroundImage: profile.photoUrl == null || profile.photoUrl!.isEmpty ? null : NetworkImage(profile.photoUrl!),
            child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                ? Text(profile.initials, style: AstraText.displayM(size: 18, color: AstraColors.cyan))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AstraText.displayM(size: 24)),
                const SizedBox(height: 3),
                Text(profile.email.isEmpty ? 'Local ASTRA profile' : profile.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AstraText.body(size: 13, color: AstraColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderReadinessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReminderReadinessState>(
      future: NotificationService.checkReminderReadiness(),
      builder: (context, snapshot) {
        var value = 'Checking…';
        var color = AstraColors.textMuted;
        final readiness = snapshot.data;
        if (readiness != null) {
          switch (readiness) {
            case ReminderReadinessState.ready:
              value = 'Ready';
              color = AstraColors.softGreen;
            case ReminderReadinessState.notificationPermissionRequired:
              value = 'Notifications off';
              color = AstraColors.amber;
            case ReminderReadinessState.exactAlarmPermissionRequired:
              value = 'Precise alarms off';
              color = AstraColors.amber;
            case ReminderReadinessState.restricted:
              value = 'Restricted';
              color = AstraColors.red;
            case ReminderReadinessState.unknown:
              value = 'Status unavailable';
              color = AstraColors.textMuted;
          }
        }
        return _SettingsRow(icon: LucideIcons.circleCheck, label: 'Reminder readiness', value: value, valueColor: color, showChevron: false);
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(title, style: AstraText.label(size: 10, color: AstraColors.cyan)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AstraColors.surface1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AstraColors.borderSubtle),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const Divider(height: 1, color: AstraColors.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showChevron;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AstraColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AstraText.metric(size: 14, color: AstraColors.textPrimary))),
          const SizedBox(width: 8),
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: AstraText.body(size: 12.5, color: valueColor ?? AstraColors.textMuted))),
          if (showChevron && onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronRight, size: 16, color: AstraColors.textMuted),
          ],
        ],
      ),
    );
    return onTap == null ? child : InkWell(onTap: onTap, child: child);
  }
}