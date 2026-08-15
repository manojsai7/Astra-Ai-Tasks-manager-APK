import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:astra/features/scheduler/data/services/google_auth_service.dart';
import 'package:astra/features/scheduler/data/services/google_calendar_writer_service.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';

/// Fake Google Event instance for test assertions.
class FakeTestCalendarEvent extends Fake implements calendar.Event {
  @override
  final String? id;
  @override
  final String? summary;
  @override
  final String? description;
  @override
  final String? location;
  @override
  final calendar.EventDateTime? start;
  @override
  final calendar.EventDateTime? end;
  @override
  final List<String>? recurrence;

  FakeTestCalendarEvent({
    this.id,
    this.summary,
    this.description,
    this.location,
    this.start,
    this.end,
    this.recurrence,
  });
}

/// Mock Google Auth Service with configurable client.
class MockGoogleAuthService extends GoogleAuthService {
  final auth.AuthClient? clientToReturn;

  MockGoogleAuthService({this.clientToReturn}) : super.mock();

  @override
  Future<auth.AuthClient?> getAuthenticatedClient() async => clientToReturn;
}

typedef CreateEventCallback = Future<calendar.Event> Function(
  auth.AuthClient client, {
  required String title,
  required DateTime startTime,
  DateTime? endTime,
  String? description,
  String? location,
  String timezone,
  RecurrenceRule? recurrenceRule,
});

/// Mock Google Calendar Writer Service for verifying writer calls.
class MockGoogleCalendarWriterService extends GoogleCalendarWriterService {
  final CreateEventCallback _handler;

  const MockGoogleCalendarWriterService(this._handler);

  @override
  Future<calendar.Event> createEvent(
    auth.AuthClient client, {
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? location,
    String timezone = 'Asia/Kolkata',
    RecurrenceRule? recurrenceRule,
  }) {
    return _handler(
      client,
      title: title,
      startTime: startTime,
      endTime: endTime,
      description: description,
      location: location,
      timezone: timezone,
      recurrenceRule: recurrenceRule,
    );
  }
}

/// Mock Auth Client for simulating Google HTTP requests.
class MockAuthClient extends http.BaseClient implements auth.AuthClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;

  MockAuthClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }

  @override
  auth.AccessCredentials get credentials => auth.AccessCredentials(
        auth.AccessToken('Bearer', 'fake_token', DateTime.now().toUtc().add(const Duration(hours: 1))),
        'fake_refresh_token',
        ['https://www.googleapis.com/auth/calendar.events'],
      );
}
