import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/focus_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system/astra_card.dart';
import '../widgets/design_system/astra_3d_button.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDuration = 25; // minutes
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedDuration * 60;
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
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
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDuration * 60;
    });
  }

  void _selectDuration(int minutes) {
    if (_isRunning) return;
    HapticFeedback.selectionClick();
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
            const SizedBox(width: 10),
            const Text('Session Done!',
                style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You focused for $_selectedDuration minutes.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'I\'ve logged it to your stats.',
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
            child: const Text('Keep going →',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
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

  Color get _timerColor {
    if (_remainingSeconds < 60) return AppTheme.error;
    if (_remainingSeconds < 300) return AppTheme.warning;
    if (_isRunning) return AppTheme.accentGreen;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(focusStatsProvider);
    final totalSeconds = _selectedDuration * 60;
    final progress =
        totalSeconds > 0 ? (1 - (_remainingSeconds / totalSeconds)) : 0.0;

    return Scaffold(
      backgroundColor: AstraColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Top Header & Stats Row ──────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FOCUS', style: AstraText.displayL(size: 34)),
                      const SizedBox(height: 4),
                      Text('Deep work mode', style: AstraText.body(size: 15, color: AstraColors.textMuted)),
                    ],
                  ),
                ),
                _StatPill(Icons.check_circle_outline, '${stats.totalSessions} SESSIONS', AstraColors.lime),
                const SizedBox(width: 8),
                _StatPill(Icons.local_fire_department_outlined, '${stats.totalMinutes}m', AstraColors.amber),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 50),

            // ── Duration Presets ──────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [15, 25, 45, 90].map((m) {
                  final active = _selectedDuration == m;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _selectDuration(m),
                      child: Container(
                        width: 74,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AstraColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active ? AstraColors.lime : AstraColors.borderSoft,
                            width: active ? 2 : 1,
                          ),
                          boxShadow: const [
                            BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
                          ],
                        ),
                        child: Text(
                          '${m}m',
                          style: AstraText.body(
                            size: 15,
                            color: active ? AstraColors.textPrimary : AstraColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 50),

            // ── Central 300x300 Timer Ring ─────────────────────
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 16,
                        backgroundColor: AstraColors.surface3,
                        valueColor: AlwaysStoppedAnimation(_timerColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: AstraText.displayXL(size: 60),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRunning ? 'FOCUSING' : 'READY',
                          style: AstraText.label(size: 14, color: _isRunning ? AstraColors.lime : AstraColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack, delay: 150.ms),

            const SizedBox(height: 40),

            // ── Insight Card ─────────────────────────────────
            AstraCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AstraColors.lime, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isRunning ? 'You\'re in the zone. Stay focused.' : 'You usually focus best in the evening.',
                      style: AstraText.body(size: 15, color: AstraColors.textMuted),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 30),

            // ── Control Buttons ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _resetTimer,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AstraColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AstraColors.borderSoft),
                      boxShadow: const [
                        BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
                      ],
                    ),
                    child: const Icon(Icons.replay_rounded, color: AstraColors.textMuted, size: 28),
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 90,
                  child: Astra3DButton(
                    height: 80,
                    depth: AstraDepth.large,
                    color: _isRunning ? AstraColors.amber : AstraColors.lime,
                    textColor: Colors.black,
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                    child: Icon(
                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 46,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AstraColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AstraColors.borderSoft),
                    boxShadow: const [
                      BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                  child: const Icon(Icons.skip_next_rounded, color: AstraColors.textMuted, size: 28),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AstraColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AstraColors.edgeSoft),
        boxShadow: const [
          BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Text(text, style: AstraText.label(size: 11, color: AstraColors.textPrimary)),
        ],
      ),
    );
  }
}

