import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/focus_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system/astra_stat_pill.dart';

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
    _timer?.cancel();
    setState(() => _isRunning = false);
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
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              _timerColor.withAlpha(_isRunning ? 22 : 8),
              AppTheme.background.withAlpha(240),
              AppTheme.background,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FOCUS',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                letterSpacing: 2,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        Text(
                          'Deep work mode',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Stats pills row
                    AstraStatPill(
                      icon: LucideIcons.checkCircle2,
                      value: '${stats.totalSessions}',
                      label: 'sessions',
                      iconColor: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    AstraStatPill(
                      icon: LucideIcons.flame,
                      value: '${stats.totalMinutes}m',
                      iconColor: AppTheme.accent,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const Spacer(flex: 2),

              // ── Duration Presets ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [15, 25, 45, 90].map((mins) {
                  final isSelected = _selectedDuration == mins;
                  return GestureDetector(
                    onTap: () => _selectDuration(mins),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withAlpha(25)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.borderSubtle,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${mins}m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const Spacer(),

              // ── Central Timer Ring ───────────────────────────────
              _TimerRing(
                progress: progress,
                isRunning: _isRunning,
                remainingSeconds: _remainingSeconds,
                timerColor: _timerColor,
                formatTime: _formatTime,
              ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    delay: 200.ms,
                  ),

              const Spacer(),

              // ── AI Hint ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.secondary.withAlpha(30), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 13, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isRunning
                              ? 'You\'re in the zone. Stay there.'
                              : 'You usually focus best in the evening.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 20),

              // ── Controls ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset button
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Icon(LucideIcons.rotateCcw,
                            size: 20, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Main play/pause button
                    GestureDetector(
                      onTap: _isRunning ? _pauseTimer : _startTimer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRunning
                              ? AppTheme.warning
                              : AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRunning
                                      ? AppTheme.warning
                                      : AppTheme.primary)
                                  .withAlpha(70),
                              blurRadius: 24,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRunning ? LucideIcons.pause : LucideIcons.play,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),
                    // Skip button placeholder
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Icon(
                        LucideIcons.skipForward,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Timer Ring Component ─────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  final double progress;
  final bool isRunning;
  final int remainingSeconds;
  final Color timerColor;
  final String Function(int) formatTime;

  const _TimerRing({
    required this.progress,
    required this.isRunning,
    required this.remainingSeconds,
    required this.timerColor,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: timerColor.withAlpha(isRunning ? 25 : 10),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Track + progress arc
          CustomPaint(
            size: const Size(240, 240),
            painter: _RingPainter(
              progress: progress,
              trackColor: AppTheme.surfaceRaised,
              fillColor: timerColor,
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatTime(remainingSeconds),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 56,
                      color: AppTheme.textPrimary,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isRunning ? 'FOCUSING' : 'READY',
                  key: ValueKey(isRunning),
                  style: TextStyle(
                    color: isRunning ? timerColor : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Fill arc
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}
