import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Thin, fully-rounded animated progress bar.
class AstraProgressBar extends StatefulWidget {
  final double value; // 0.0 – 1.0
  final double height;
  final Color? fillColor;
  final Color? trackColor;
  final Duration animationDuration;

  const AstraProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.fillColor,
    this.trackColor,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AstraProgressBar> createState() => _AstraProgressBarState();
}

class _AstraProgressBarState extends State<AstraProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    _animation = Tween<double>(begin: 0, end: widget.value.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AstraProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.fillColor ?? AppTheme.primary;
    final track = widget.trackColor ?? AppTheme.surfaceRaised;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.height),
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: widget.height,
                    width: constraints.maxWidth,
                    color: track,
                  ),
                  // Fill
                  Container(
                    height: widget.height,
                    width: constraints.maxWidth * _animation.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [fill, fill.withAlpha(180)],
                      ),
                      borderRadius: BorderRadius.circular(widget.height),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
