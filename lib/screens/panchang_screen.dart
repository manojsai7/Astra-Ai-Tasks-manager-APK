import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Ekadashi', 'Purnima', 'Amavasya', 'Shivaratri'];

  @override
  void initState() {
    super.initState();
    // Auto-schedule notifications for upcoming events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(panchangEventsProvider).whenData((events) {
        ref
            .read(panchangNotificationProvider.notifier)
            .scheduleAllUpcomingReminders(events);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(panchangEventsProvider);
    final todayInfo = ref.watch(todayPanchangProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeader(todayInfo),
            ),
            title: Text(
              'Telugu Panchang',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: _buildFilterRow(),
          ),

          // Events list
          eventsAsync.when(
            data: (events) {
              final filtered = _selectedFilter == 'All'
                  ? events
                  : events.where((e) => e.eventName == _selectedFilter).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    final event = filtered[index];
                    return _PanchangEventCard(event: event, index: index);
                  },
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accent),
                    const SizedBox(height: 16),
                    Text(
                      'Computing Panchang…',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            error: (e, s) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $e',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, String> todayInfo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1025),
            AppTheme.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative radial glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withAlpha(40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withAlpha(30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text('🕉️', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Text(
                      'Telugu Panchang',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                const SizedBox(height: 4),
                Text(
                  'Hyderabad, Telangana · IST',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),
                // Today's Panchang card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated.withAlpha(180),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.accent.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _TodayInfoChip(
                        icon: '🌞',
                        label: 'Tithi',
                        value: todayInfo['tithi'] ?? '…',
                      ),
                      _VertDivider(),
                      _TodayInfoChip(
                        icon: '📅',
                        label: 'Month',
                        value: todayInfo['month'] ?? '…',
                      ),
                      _VertDivider(),
                      _TodayInfoChip(
                        icon: '🌅',
                        label: 'Sunrise',
                        value: todayInfo['sunrise'] ?? '…',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      height: 56,
      color: AppTheme.background,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final filter = _filters[i];
          final isActive = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accent : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.accent : AppTheme.surfaceGlass,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🕉️', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          'No $_selectedFilter events found',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'in the next 3 months',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.surfaceGlass,
    );
  }
}

class _TodayInfoChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _TodayInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PanchangEventCard extends StatelessWidget {
  final PanchangEvent event;
  final int index;

  const _PanchangEventCard({required this.event, required this.index});

  Color _getEventColor() {
    switch (event.eventName) {
      case 'Ekadashi':
        return const Color(0xFF7C65F4); // Indigo
      case 'Purnima':
        return const Color(0xFFF59E0B); // Golden
      case 'Amavasya':
        return const Color(0xFF6366F1); // Deep purple
      case 'Shivaratri':
        return const Color(0xFF10B981); // Emerald
      default:
        return AppTheme.accent;
    }
  }

  String _getDaysLabel() {
    final days = event.daysFromNow;
    if (days == 0) return 'Today 🎉';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor();
    final days = event.daysFromNow;
    final isUrgent = days <= 3;
    final isToday = days == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? color.withAlpha(120)
              : isUrgent
                  ? color.withAlpha(60)
                  : color.withAlpha(25),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 16,
                  spreadRadius: -4,
                )
              ]
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar + emoji
            Container(
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withAlpha(40), color.withAlpha(15)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(event.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(event.eventDate),
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(event.eventDate).toUpperCase(),
                    style: TextStyle(
                      color: color.withAlpha(180),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.displayName,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _DaysChip(label: _getDaysLabel(), color: color, isUrgent: isUrgent || isToday),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.lunarMonth,
                      style: TextStyle(
                        color: color.withAlpha(200),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Day of week chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withAlpha(40)),
                      ),
                      child: Text(
                        DateFormat('EEEE, MMM d, yyyy').format(event.eventDate),
                        style: TextStyle(
                          color: color.withAlpha(220),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 400.ms)
        .slideX(begin: 0.05, duration: 350.ms);
  }
}

class _DaysChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isUrgent;

  const _DaysChip({
    required this.label,
    required this.color,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? color.withAlpha(30) : AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent ? color.withAlpha(80) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isUrgent ? color : AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
