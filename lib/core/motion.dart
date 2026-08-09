import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumMotion {
  static List<Effect> listItemEnter() => [
        const FadeEffect(duration: Duration(milliseconds: 300), curve: Curves.easeOut),
        const MoveEffect(
          begin: Offset(0, 10),
          end: Offset.zero,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      ];
}

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
}
