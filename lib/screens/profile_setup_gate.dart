import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/profile_provider.dart';
import '../services/haptics/astra_haptics.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ProfileSetupGate extends ConsumerStatefulWidget {
  const ProfileSetupGate({super.key});

  @override
  ConsumerState<ProfileSetupGate> createState() => _ProfileSetupGateState();
}

class _ProfileSetupGateState extends ConsumerState<ProfileSetupGate> {
  bool _promptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    if (!mounted || _promptShown) return;
    _promptShown = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('astra_profile_prompt_seen') ?? false) return;

    final profile = ref.read(astraProfileProvider);
    if (profile.nickname.trim().isNotEmpty || profile.email.trim().isNotEmpty) {
      await prefs.setBool('astra_profile_prompt_seen', true);
      return;
    }

    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AstraColors.surface1,
        title: const Text('What should ASTRA call you?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Your nickname',
            counterText: '',
          ),
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('NOT NOW'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();

    await prefs.setBool('astra_profile_prompt_seen', true);
    if (!mounted || value == null || value.isEmpty) return;
    await ref.read(astraProfileProvider.notifier).setNickname(value);
    await AstraHaptics.success();
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
