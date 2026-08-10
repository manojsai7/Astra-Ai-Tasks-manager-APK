import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/panchang_service.dart';
import '../services/notification_service.dart';

/// Fetches upcoming Panchang events for the next 3 months.
final panchangEventsProvider = FutureProvider<List<PanchangEvent>>((ref) async {
  return PanchangService.getUpcomingEvents(months: 3);
});

/// Today's Tithi display string.
final todayTithiProvider = Provider<String>((ref) {
  return PanchangService.getTodayTithiDisplay();
});

/// Today's full Panchang info map.
final todayPanchangProvider = Provider<Map<String, String>>((ref) {
  return PanchangService.getTodayPanchang();
});

/// Notifier to handle scheduling notifications for Panchang events.
class PanchangNotificationNotifier extends StateNotifier<Set<String>> {
  PanchangNotificationNotifier() : super({});

  Future<void> scheduleEventReminder(PanchangEvent event) async {
    final key = '${event.eventName}_${event.eventDate.toIso8601String()}';
    if (state.contains(key)) return; // Already scheduled

    // Remind at 6:00 AM on the day before
    final reminderTime = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
    ).subtract(const Duration(days: 1)).add(const Duration(hours: 6));

    // Remind at 6:00 AM on the day itself
    final dayOfReminder = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
      6,
    );

    final baseId = '${event.eventName}_${event.eventDate.millisecondsSinceEpoch}'.hashCode;

    await NotificationService.scheduleTaskReminder(
      id: baseId,
      title: '${event.emoji} Tomorrow: ${event.displayName}',
      body: event.description,
      scheduledTime: reminderTime,
    );

    await NotificationService.scheduleTaskReminder(
      id: baseId + 1,
      title: '${event.emoji} Today: ${event.displayName}',
      body: event.description,
      scheduledTime: dayOfReminder,
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
