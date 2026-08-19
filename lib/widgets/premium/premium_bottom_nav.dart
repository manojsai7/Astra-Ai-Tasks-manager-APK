import 'package:flutter/material.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../theme/app_theme.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const items = [
    (Icons.home_rounded, 'HOME'),
    (Icons.checklist_rounded, 'TASKS'),
    (Icons.timer_outlined, 'FOCUS'),
    (Icons.calendar_month_outlined, 'PANCHANG'),
    (Icons.auto_awesome, 'ASTRA'),
  ];

  @override
  Widget build(BuildContext context) {
    // Hide navigation bar when keyboard is open to prevent overlapping composers/inputs
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final availableWidth = MediaQuery.sizeOf(context).width;
    final navHeight = (availableWidth * 0.16).clamp(66.0, 76.0);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: navHeight,
        decoration: BoxDecoration(
          color: AstraColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AstraColors.edge, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AstraColors.depth,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            final item = items[i];
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  AstraHaptics.selection();
                  onTap(i);
                },
                child: AnimatedContainer(
                  duration: AstraMotion.standard,
                  curve: AstraMotion.curve,
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 22,
                        color: active ? AstraColors.lime : AstraColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.$2,
                          maxLines: 1,
                          style: AstraText.label(
                            size: 10,
                            color: active ? AstraColors.lime : AstraColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: AstraMotion.standard,
                        width: active ? 22 : 0,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AstraColors.lime,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

typedef AstraBottomNav = PremiumBottomNav;
