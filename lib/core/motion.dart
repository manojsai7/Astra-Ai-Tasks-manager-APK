import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Motion Graphics Library for ASTRA
/// Provides physics-based spring curves, page transitions, scale micro-interactions,
/// and animated numerical counters.
class PremiumMotion {
  /// Physics-based spring ease curve
  static const Curve springCurve = Curves.easeOutCubic;
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 350);
  static const Duration longDuration = Duration(milliseconds: 500);

  /// Staggered item entry animation effects
  static List<Effect> listItemEnter({int delayMs = 0}) => [
        FadeEffect(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          delay: Duration(milliseconds: delayMs),
        ),
        MoveEffect(
          begin: const Offset(0, 12),
          end: Offset.zero,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          delay: Duration(milliseconds: delayMs),
        ),
      ];
}

/// Extension for easily applying staggered entrance animations to widgets
extension PremiumAnimationExtension on Widget {
  Widget withPremiumEntry({int delayMs = 0}) => animate(
        delay: Duration(milliseconds: delayMs),
      )
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.05,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          );

  /// Wraps any widget with a tactile scale-down micro-interaction on press
  Widget withScalePress({
    VoidCallback? onTap,
    double scaleDown = 0.94,
  }) {
    return AstraPressScale(
      onTap: onTap,
      scaleDown: scaleDown,
      child: this,
    );
  }
}

/// Tactile press scale wrapper widget
class AstraPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const AstraPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.94,
  });

  @override
  State<AstraPressScale> createState() => _AstraPressScaleState();
}

class _AstraPressScaleState extends State<AstraPressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap!();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (ctx, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Animated Numerical Counter (scale + fade transition on value change)
class AstraAnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String? suffix;

  const AstraAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final text = suffix != null ? '$value$suffix' : '$value';
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        style: style,
      ),
    );
  }
}

/// Custom Physics-Based Page Route (Slide Up + Fade)
class AstraPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AstraPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.04, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

/// Custom PageTransitionsBuilder for ThemeData
class AstraPageTransitionsBuilder extends PageTransitionsBuilder {
  const AstraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}
