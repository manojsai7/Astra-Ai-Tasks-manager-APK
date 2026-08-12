import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/panchang_provider.dart';
import '../services/panchang_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system/astra_card.dart';

class PanchangScreen extends ConsumerStatefulWidget {
  const PanchangScreen({super.key});

  @override
  ConsumerState<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends ConsumerState<PanchangScreen> {
  static const _filters = ['ALL', 'EKADASHI', 'PURNIMA', 'AMAVASYA', 'SHIVARATRI'];
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(panchangEventsProvider).whenData(
        (events) => ref.read(panchangNotificationProvider.notifier).scheduleAllUpcomingReminders(events),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(panchangEventsProvider);
    final today = ref.watch(todayPanchangProvider);

    return Scaffold(
      backgroundColor: AstraColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            Text('PANCHANG', style: AstraText.displayL(size: 34)),
            const SizedBox(height: 18),
            Text('DAILY RHYTHM', style: AstraText.label(size: 14, color: AstraColors.lime)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('TELUGU\nPANCHANG', style: AstraText.displayXL(size: 56)),
            ),
            const SizedBox(height: 10),
            Text('HYDERABAD · TELANGANA · IST', style: AstraText.label(size: 13, color: AstraColors.textMuted)),
            const SizedBox(height: 22),

            // Today's Panchang Metrics Card
            AstraCard(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Row(
                children: [
                  _InfoMetric(
                    Icons.nightlight_outlined,
                    'TITHI',
                    today['tithi'] ?? 'Chaturdashi\n(Krishna Paksha)',
                    AstraColors.violet,
                  ),
                  const _VerticalDivider(),
                  _InfoMetric(
                    Icons.calendar_month_outlined,
                    'MONTH',
                    today['month'] ?? 'Shravana',
                    AstraColors.lime,
                  ),
                  const _VerticalDivider(),
                  _InfoMetric(
                    Icons.wb_sunny_outlined,
                    'SUNRISE',
                    today['sunrise'] ?? '05:57 IST',
                    AstraColors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Observance Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _filters.map((filter) {
                  final active = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _FilterPill(
                      label: filter,
                      active: active,
                      onTap: () => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Panchang Events List
            events.when(
              data: (items) {
                final filtered = _selectedFilter == 'ALL'
                    ? items
                    : items.where((event) => event.eventName.toUpperCase() == _selectedFilter).toList();

                if (filtered.isEmpty) {
                  return const _EmptyPanchangState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _Panchang3DEventCard(
                    event: filtered[index],
                    index: index,
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AstraColors.lime),
                ),
              ),
              error: (_, _) => const _ErrorPanchangState(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: AstraTheme.label(size: 10, color: AstraColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AstraTheme.body(size: 13, color: AstraColors.text),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 60,
      color: AstraColors.edgeSoft,
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AstraMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AstraColors.lime : AstraColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AstraColors.lime : AstraColors.edgeSoft),
          boxShadow: const [
            BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Text(
          label,
          style: AstraTheme.label(
            size: 12,
            color: active ? Colors.black : AstraColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Panchang3DEventCard extends StatelessWidget {
  const _Panchang3DEventCard({required this.event, required this.index});
  final PanchangEvent event;
  final int index;

  PanchangVisualType get _visualType => switch (event.eventName) {
        'Ekadashi' => PanchangVisualType.fasting,
        'Purnima' => PanchangVisualType.lunar,
        'Amavasya' => PanchangVisualType.lunar,
        'Shivaratri' => PanchangVisualType.festival,
        _ => PanchangVisualType.auspicious,
      };

  Color get _accentColor => PanchangTheme.colorFor(_visualType);

  String get _relativeDay => event.daysFromNow == 0
      ? 'TODAY'
      : event.daysFromNow == 1
          ? 'TOMORROW'
          : 'IN ${event.daysFromNow} DAYS';

  @override
  Widget build(BuildContext context) {
    return AstraCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accentColor.withValues(alpha: .4)),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('d').format(event.eventDate),
                  style: AstraTheme.display(size: 32, color: _accentColor),
                ),
                Text(
                  DateFormat('MMM').format(event.eventDate).toUpperCase(),
                  style: AstraTheme.label(size: 11, color: _accentColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AstraTheme.label(size: 15, color: AstraColors.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _accentColor.withValues(alpha: .5)),
                      ),
                      child: Text(
                        _relativeDay,
                        style: AstraTheme.label(size: 10, color: _accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.lunarMonth.toUpperCase(),
                  style: AstraTheme.label(size: 11, color: AstraColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AstraTheme.body(size: 13, color: AstraColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 250.ms).slideY(begin: .04, end: 0);
  }
}

class _EmptyPanchangState extends StatelessWidget {
  const _EmptyPanchangState();

  @override
  Widget build(BuildContext context) {
    return AstraCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.calendar_month_outlined, color: AstraColors.textMuted, size: 38),
          const SizedBox(height: 12),
          Text('NO OBSERVANCES FOUND', style: AstraTheme.label(size: 14, color: AstraColors.text)),
          const SizedBox(height: 6),
          Text(
            'Try selecting another filter from the bar above.',
            style: AstraTheme.body(size: 13, color: AstraColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorPanchangState extends StatelessWidget {
  const _ErrorPanchangState();

  @override
  Widget build(BuildContext context) {
    return AstraCard(
      padding: const EdgeInsets.all(24),
      borderColor: AstraColors.red.withValues(alpha: .5),
      child: Center(
        child: Text(
          'UNABLE TO LOAD PANCHANG DATA',
          style: AstraTheme.label(size: 13, color: AstraColors.red),
        ),
      ),
    );
  }
}
