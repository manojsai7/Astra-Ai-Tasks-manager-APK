import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/focus_provider.dart';
import '../theme/app_theme.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _selectedDuration = 25; // minutes
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedDuration * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          ref.read(focusStatsProvider.notifier).addSession(_selectedDuration);
          _remainingSeconds = _selectedDuration * 60;
        });
        _showCompletionDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDuration * 60;
    });
  }

  void _selectDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedDuration = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.trophy, color: AppTheme.warning, size: 24),
            const SizedBox(width: 8),
            const Text('Session Complete!', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You focused for $_selectedDuration minutes!',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep up the momentum!',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
            },
            child: const Text('Awesome!', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(focusStatsProvider);
    final totalSeconds = _selectedDuration * 60;
    final progress = totalSeconds > 0 ? (1 - (_remainingSeconds / totalSeconds)) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Focus Arena'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Stats header
              Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      icon: LucideIcons.checkCircle2,
                      label: 'Sessions',
                      value: '${stats.totalSessions}',
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatPill(
                      icon: LucideIcons.timer,
                      label: 'Total min',
                      value: '${stats.totalMinutes}',
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatPill(
                      icon: LucideIcons.flame,
                      label: 'Streak',
                      value: '3',
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Circular timer with progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceElevated.withAlpha(50),
                    ),
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _remainingSeconds < 60
                            ? AppTheme.error
                            : _remainingSeconds < 300
                                ? AppTheme.warning
                                : AppTheme.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_remainingSeconds),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      _isRunning
                          ? const Text(
                              'FOCUSING',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .fade(duration: 1000.ms, begin: 0.5, end: 1.0)
                          : const Text(
                              'READY',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Duration presets
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [15, 25, 45, 60].map((mins) {
                  final isSelected = _selectedDuration == mins;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _DurationChip(
                      label: '${mins}m',
                      isSelected: isSelected,
                      onTap: () => _selectDuration(mins),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRunning)
                    _ControlButton(
                      icon: LucideIcons.pause,
                      label: 'Pause',
                      onTap: _pauseTimer,
                      color: AppTheme.warning,
                    )
                  else
                    _ControlButton(
                      icon: LucideIcons.play,
                      label: 'Start',
                      onTap: _startTimer,
                      color: AppTheme.success,
                    ),
                  const SizedBox(width: 16),
                  _ControlButton(
                    icon: LucideIcons.rotateCcw,
                    label: 'Reset',
                    onTap: _resetTimer,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Stay focused. Every second counts.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color == AppTheme.textMuted ? AppTheme.surfaceElevated : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
