import 'dart:io';

import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import '../../../../services/assistant/astra_recurrence_engine.dart';

/// Structured error codes for Google Calendar writing operations.
enum GoogleCalendarWriteErrorCode {
  authRequired,
  permissionRequired,
  networkError,
  apiError,
}

/// Exception thrown when Google Calendar event creation fails.
class GoogleCalendarWriteException implements Exception {
  final GoogleCalendarWriteErrorCode code;
  final String message;
  final dynamic originalError;

  const GoogleCalendarWriteException({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'GoogleCalendarWriteException($code): $message';
}

/// Standalone service for creating events in Google Calendar via the Google Calendar REST API.
class GoogleCalendarWriterService {
  const GoogleCalendarWriterService();

  /// Creates an event in the user's primary Google Calendar.
  Future<calendar.Event> createEvent(
    auth.AuthClient client, {
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? location,
    String timezone = 'Asia/Kolkata',
    RecurrenceRule? recurrenceRule,
  }) async {
    final calendarApi = calendar.CalendarApi(client);

    // Default duration is exactly 1 hour if endTime is null
    final resolvedEnd = endTime ?? startTime.add(const Duration(hours: 1));

    final startEventDateTime = calendar.EventDateTime(
      dateTime: startTime.toUtc(),
      timeZone: timezone,
    );

    final endEventDateTime = calendar.EventDateTime(
      dateTime: resolvedEnd.toUtc(),
      timeZone: timezone,
    );

    final eventToInsert = calendar.Event(
      summary: title,
      description: description,
      location: location,
      start: startEventDateTime,
      end: endEventDateTime,
    );

    if (recurrenceRule != null && recurrenceRule.frequency != RecurrenceFrequency.none) {
      final rrule = _mapRecurrenceRuleToRRule(recurrenceRule);
      if (rrule != null) {
        eventToInsert.recurrence = [rrule];
      }
    }

    try {
      final createdEvent = await calendarApi.events.insert(
        eventToInsert,
        'primary',
      );
      return createdEvent;
    } on calendar.DetailedApiRequestError catch (e) {
      if (e.status == 401) {
        throw GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.authRequired,
          message: 'Authentication expired or invalid. Please re-authenticate.',
          originalError: e,
        );
      } else if (e.status == 403) {
        throw GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.permissionRequired,
          message: 'Insufficient Calendar permissions. "calendar.events" scope required.',
          originalError: e,
        );
      } else {
        throw GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.apiError,
          message: 'Google Calendar API error: ${e.message}',
          originalError: e,
        );
      }
    } on SocketException catch (e) {
      throw GoogleCalendarWriteException(
        code: GoogleCalendarWriteErrorCode.networkError,
        message: 'Network error connecting to Google Calendar API: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socket') || errStr.contains('network') || errStr.contains('connection')) {
        throw GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.networkError,
          message: 'Network connectivity error: $e',
          originalError: e,
        );
      }
      if (errStr.contains('403') || errStr.contains('permission') || errStr.contains('access_denied')) {
        throw GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.permissionRequired,
          message: 'Calendar write permission denied: $e',
          originalError: e,
        );
      }
      if (errStr.contains('401') || errStr.contains('unauthenticated') || errStr.contains('auth')) {
        throw GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.authRequired,
          message: 'Google Authentication required: $e',
          originalError: e,
        );
      }
      throw GoogleCalendarWriteException(
        code: GoogleCalendarWriteErrorCode.apiError,
        message: 'Unexpected error creating Google Calendar event: $e',
        originalError: e,
      );
    }
  }

  /// Maps an internal [RecurrenceRule] to an RFC 5545 RRULE string compatible with Google Calendar.
  String? _mapRecurrenceRuleToRRule(RecurrenceRule rule) {
    String base;
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        base = 'RRULE:FREQ=DAILY';
        if (rule.interval > 1) {
          base += ';INTERVAL=${rule.interval}';
        }
        break;

      case RecurrenceFrequency.weekdays:
        base = 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
        break;

      case RecurrenceFrequency.weekly:
        final days = rule.byWeekdays.isNotEmpty
            ? rule.byWeekdays.map(_weekdayToRrule).join(',')
            : (rule.startDate != null ? _weekdayToRrule(rule.startDate!.weekday) : 'MO');
        base = 'RRULE:FREQ=WEEKLY;BYDAY=$days';
        if (rule.interval > 1) {
          base += ';INTERVAL=${rule.interval}';
        }
        break;

      case RecurrenceFrequency.monthly:
        final monthDay = rule.startDate?.day ?? (rule.hour > 0 ? rule.hour : 1);
        base = 'RRULE:FREQ=MONTHLY;BYMONTHDAY=$monthDay';
        if (rule.interval > 1) {
          base += ';INTERVAL=${rule.interval}';
        }
        break;

      case RecurrenceFrequency.yearly:
        base = 'RRULE:FREQ=YEARLY';
        if (rule.interval > 1) {
          base += ';INTERVAL=${rule.interval}';
        }
        break;

      case RecurrenceFrequency.custom:
      case RecurrenceFrequency.none:
        return null;
    }

    if (rule.endDate != null) {
      final utc = rule.endDate!.toUtc();
      final until = _formatUntil(utc);
      base += ';UNTIL=$until';
    }

    return base;
  }

  String _weekdayToRrule(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'MO';
      case DateTime.tuesday:
        return 'TU';
      case DateTime.wednesday:
        return 'WE';
      case DateTime.thursday:
        return 'TH';
      case DateTime.friday:
        return 'FR';
      case DateTime.saturday:
        return 'SA';
      case DateTime.sunday:
        return 'SU';
      default:
        return 'MO';
    }
  }

  String _formatUntil(DateTime date) {
    final buffer = StringBuffer();
    buffer.write(date.year.toString().padLeft(4, '0'));
    buffer.write(date.month.toString().padLeft(2, '0'));
    buffer.write(date.day.toString().padLeft(2, '0'));
    buffer.write('T');
    buffer.write(date.hour.toString().padLeft(2, '0'));
    buffer.write(date.minute.toString().padLeft(2, '0'));
    buffer.write(date.second.toString().padLeft(2, '0'));
    buffer.write('Z');
    return buffer.toString();
  }
}
