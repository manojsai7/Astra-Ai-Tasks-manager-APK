import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

/// Data container for extracted Google Calendar event info.
class CalendarEventData {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime? endTime;
  final String? htmlLink;

  CalendarEventData({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    this.endTime,
    this.htmlLink,
  });
}

/// Service that queries upcoming events from Google Calendar API.
class CalendarSyncService {
  /// Fetches upcoming events from user's primary calendar for specified range in days.
  Future<List<CalendarEventData>> fetchUpcomingEvents(
    auth.AuthClient client, {
    int daysAhead = 30,
    int maxResults = 50,
  }) async {
    final calendarApi = calendar.CalendarApi(client);
    final now = DateTime.now();
    final future = now.add(Duration(days: daysAhead));

    final response = await calendarApi.events.list(
      'primary',
      timeMin: now.toUtc(),
      timeMax: future.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: maxResults,
    );

    final List<CalendarEventData> events = [];
    final items = response.items ?? [];

    for (final item in items) {
      if (item.id == null || item.summary == null) continue;

      final startDateTime = item.start?.dateTime ?? item.start?.date;
      if (startDateTime == null) continue;

      events.add(
        CalendarEventData(
          id: item.id!,
          title: item.summary!,
          description: item.description,
          location: item.location,
          startTime: startDateTime.toLocal(),
          endTime: (item.end?.dateTime ?? item.end?.date)?.toLocal(),
          htmlLink: item.htmlLink,
        ),
      );
    }

    return events;
  }
}
