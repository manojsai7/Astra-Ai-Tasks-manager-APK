import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const labels = ['Home', 'Tasks', 'Focus', 'Panchang', 'ASTRA'];
    const icons = [
      Icons.home_outlined,
      Icons.checklist_outlined,
      Icons.timer_outlined,
      Icons.calendar_month_outlined,
      Icons.auto_awesome_outlined
    ];
    const activeIcons = [
      Icons.home,
      Icons.checklist,
      Icons.timer,
      Icons.calendar_month,
      Icons.auto_awesome
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.s16, vertical: AppTheme.s8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.r24),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.r24),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: List.generate(5, (i) {
            final isSelected = currentIndex == i;
            return BottomNavigationBarItem(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(isSelected ? activeIcons[i] : icons[i], size: 24),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              label: labels[i],
            );
          }),
        ),
      ),
    );
  }
}
