import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../theme/app_theme.dart';

enum TaskViewFilter {
  myDay('MY DAY', LucideIcons.sunMedium),
  upcoming('UPCOMING', LucideIcons.calendarDays),
  important('IMPORTANT', LucideIcons.star),
  all('ALL', LucideIcons.layoutList),
  recurring('RECURRING', LucideIcons.repeat),
  completed('COMPLETED', LucideIcons.checkCircle2);

  final String label;
  final IconData icon;
  const TaskViewFilter(this.label, this.icon);

  /// Backward-compatible alias
  static const TaskViewFilter priority = TaskViewFilter.important;
}

class TasksViewTabs extends StatelessWidget {
  final TaskViewFilter selectedView;
  final ValueChanged<TaskViewFilter> onSelectView;
  final Map<TaskViewFilter, int>? counts;

  const TasksViewTabs({
    super.key,
    required this.selectedView,
    required this.onSelectView,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TaskViewFilter.values.map((view) {
          final isSelected = view == selectedView;
          final count = counts?[view];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                AstraHaptics.selection();
                onSelectView(view);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AstraColors.surface2 : AstraColors.surface0,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AstraColors.cyan : AstraColors.borderSubtle,
                    width: isSelected ? 1.2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AstraColors.cyan.withValues(alpha: 0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: AstraColors.depth,
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      view.icon,
                      size: 13,
                      color: isSelected ? AstraColors.lime : AstraColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      view.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isSelected ? AstraColors.textPrimary : AstraColors.textMuted,
                      ),
                    ),
                    if (count != null && count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AstraColors.cyan.withValues(alpha: 0.2)
                              : AstraColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AstraColors.cyan : AstraColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
