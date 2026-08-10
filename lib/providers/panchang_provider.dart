import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/panchang_service.dart';
import '../services/notification_service.dart';

/// Fetches upcoming Panchang events for the next 3 months and
/// automatically schedules notifications for each one.
final panchangEventsProvider = FutureProvider<List<PanchangEvent>>((ref) async {
  final events = PanchangService.getUpcomingEvents(months: 3);

  // Auto-schedule reminders for every upcoming event
  for (final event in events) {
    final baseId =
        '${event.eventName}_${event.eventDate.millisecondsSinceEpoch}'.hashCode;

    // 1. Day-before reminder at 06:00
    final dayBefore = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
    ).subtract(const Duration(days: 1)).add(const Duration(hours: 6));

    await NotificationService.schedulePanchangReminder(
      id: baseId,
      title: '${event.emoji} Tomorrow: ${event.displayName}',
      body: event.description,
      scheduledTime: dayBefore,
    );

    // 2. Day-of reminder at 06:00
    final dayOf = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
      6,
    );

    await NotificationService.schedulePanchangReminder(
      id: baseId + 1,
      title: '${event.emoji} Today: ${event.displayName}',
      body: event.description,
      scheduledTime: dayOf,
    );
  }

  return events;
});

/// Today's Tithi display string (e.g. "Shravana Krishna Ekadashi").
final todayTithiProvider = Provider<String>((ref) {
  return PanchangService.getTodayTithiDisplay();
});

/// Today's full Panchang info map (tithi, month, sunrise).
final todayPanchangProvider = Provider<Map<String, String>>((ref) {
  return PanchangService.getTodayPanchang();
});

// ---------------------------------------------------------------------------
// Manual notification notifier (kept for on-demand use from PanchangScreen)
// ---------------------------------------------------------------------------

class PanchangNotificationNotifier extends StateNotifier<Set<String>> {
  PanchangNotificationNotifier() : super({});

  Future<void> scheduleEventReminder(PanchangEvent event) async {
    final key = '${event.eventName}_${event.eventDate.toIso8601String()}';
    if (state.contains(key)) return;

    final baseId =
        '${event.eventName}_${event.eventDate.millisecondsSinceEpoch}'.hashCode;

    final dayBefore = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
    ).subtract(const Duration(days: 1)).add(const Duration(hours: 6));

    final dayOf = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
      6,
    );

    await NotificationService.schedulePanchangReminder(
      id: baseId,
      title: '${event.emoji} Tomorrow: ${event.displayName}',
      body: event.description,
      scheduledTime: dayBefore,
    );

    await NotificationService.schedulePanchangReminder(
      id: baseId + 1,
      title: '${event.emoji} Today: ${event.displayName}',
      body: event.description,
      scheduledTime: dayOf,
    );

    state = {...state, key};
  }

  Future<void> scheduleAllUpcomingReminders(List<PanchangEvent> events) async {
    for (final event in events) {
      await scheduleEventReminder(event);
    }
  }
}

final panchangNotificationProvider =
    StateNotifierProvider<PanchangNotificationNotifier, Set<String>>(
  (ref) => PanchangNotificationNotifier(),
);

// ---------------------------------------------------------------------------
// Helper: format events into a readable list for the Assistant
// ---------------------------------------------------------------------------

String formatEventsForAssistant(List<PanchangEvent> events, {int limit = 6}) {
  if (events.isEmpty) return '🕉️ No upcoming Panchang events in the next 3 months.';

  final buf = StringBuffer('🕉️ *Upcoming Panchang Events*\n\n');
  int shown = 0;
  for (final e in events) {
    if (shown >= limit) break;
    final dateStr = DateFormat('EEE, d MMM').format(e.eventDate);
    final days = e.daysFromNow;
    final when = days == 0
        ? 'Today!'
        : days == 1
            ? 'Tomorrow'
            : 'In $days days';
    buf.writeln('${e.emoji} *${e.displayName}*');
    buf.writeln('   📅 $dateStr  ·  $when');
    buf.writeln('   ${e.description}');
    buf.writeln();
    shown++;
  }
  if (events.length > limit) {
    buf.write('...and ${events.length - limit} more events.');
  }
  return buf.toString().trim();
}
