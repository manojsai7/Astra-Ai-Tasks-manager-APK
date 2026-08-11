import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/panchang_provider.dart';
import '../services/panchang_service.dart';
import '../theme/app_theme.dart';

class PanchangScreen extends ConsumerStatefulWidget {
  const PanchangScreen({super.key});

  @override
  ConsumerState<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends ConsumerState<PanchangScreen> {
  static const _filters = ['All', 'Ekadashi', 'Purnima', 'Amavasya', 'Shivaratri'];
  String _selectedFilter = 'All';

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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 292,
            backgroundColor: AppTheme.background,
            surfaceTintColor: Colors.transparent,
            title: Text('PANCHANG', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 22)),
            flexibleSpace: FlexibleSpaceBar(background: _PanchangHero(info: today)),
          ),
          SliverToBoxAdapter(child: _filterBar()),
          events.when(
            data: (items) {
              final filtered = _selectedFilter == 'All'
                  ? items
                  : items.where((event) => event.eventName == _selectedFilter).toList();
              if (filtered.isEmpty) return SliverFillRemaining(child: _emptyState());
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _PanchangEventCard(event: filtered[index], index: index),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
            error: (_, _) => SliverFillRemaining(child: _errorState()),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() => Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          border: Border(bottom: BorderSide(color: AppTheme.borderFaint)),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final label = _filters[index];
            final selected = label == _selectedFilter;
            return _Pressable(
              onTap: () => setState(() => _selectedFilter = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? AppTheme.primary : AppTheme.borderSubtle),
                  boxShadow: selected ? const [BoxShadow(color: AppTheme.primaryDark, offset: Offset(0, 3))] : null,
                ),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: selected ? Colors.black : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _emptyState() => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_outlined, color: AppTheme.textMuted, size: 36),
          SizedBox(height: 12),
          Text('NO EVENTS IN THIS VIEW', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, letterSpacing: .8)),
          SizedBox(height: 5),
          Text('Try another observance filter.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ]),
      );

  Widget _errorState() => const Center(
        child: Text('PANCHANG DATA COULD NOT BE LOADED', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
      );
}

class _PanchangHero extends StatelessWidget {
  const _PanchangHero({required this.info});
  final Map<String, String> info;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DAILY RHYTHM', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 11)),
            const SizedBox(height: 6),
            Text('TELUGU\nPANCHANG', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 42, height: .84, letterSpacing: .5)),
            const SizedBox(height: 10),
            Text('HYDERABAD · TELANGANA · IST', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textMuted, letterSpacing: .8)),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 4))],
              ),
              child: Row(children: [
                _PanchangMetric(label: 'TITHI', value: info['tithi'] ?? '—', icon: Icons.brightness_2_outlined),
                _metricDivider(),
                _PanchangMetric(label: 'MONTH', value: info['month'] ?? '—', icon: Icons.calendar_month_outlined),
                _metricDivider(),
                _PanchangMetric(label: 'SUNRISE', value: info['sunrise'] ?? '—', icon: Icons.wb_sunny_outlined),
              ]),
            ),
          ]),
        ),
      );

  Widget _metricDivider() => const SizedBox(height: 48, child: VerticalDivider(width: 1, color: AppTheme.borderSubtle));
}

class _PanchangMetric extends StatelessWidget {
  const _PanchangMetric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
          child: Column(children: [
            Icon(icon, color: AppTheme.primary, size: 15),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .8)),
            const SizedBox(height: 2),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _PanchangEventCard extends StatelessWidget {
  const _PanchangEventCard({required this.event, required this.index});
  final PanchangEvent event;
  final int index;

  Color get _color => switch (event.eventName) {
        'Ekadashi' => AppTheme.primary,
        'Purnima' => AppTheme.accent,
        'Amavasya' => AppTheme.accentPurple,
        'Shivaratri' => AppTheme.success,
        _ => AppTheme.secondary,
      };

  String get _relativeDay => event.daysFromNow == 0 ? 'TODAY' : event.daysFromNow == 1 ? 'TOMORROW' : 'IN ${event.daysFromNow} DAYS';

  @override
  Widget build(BuildContext context) => _Pressable(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: event.daysFromNow <= 3 ? _color.withValues(alpha: .65) : AppTheme.borderSubtle),
            boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: _color, borderRadius: const BorderRadius.horizontal(left: Radius.circular(13))),
              child: Column(children: [
                Text(DateFormat('d').format(event.eventDate), style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 3),
                Text(DateFormat('MMM').format(event.eventDate).toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(event.displayName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .2))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: _color.withValues(alpha: .15), borderRadius: BorderRadius.circular(5)), child: Text(_relativeDay, style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5))),
                  ]),
                  const SizedBox(height: 4),
                  Text(event.lunarMonth.toUpperCase(), style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .5)),
                  const SizedBox(height: 7),
                  Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35)),
                ]),
              ),
            ),
          ]),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 45 * index), duration: 260.ms).slideY(begin: .04, end: 0);
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(duration: const Duration(milliseconds: 100), scale: _pressed ? .985 : 1, child: widget.child),
      );
}
