import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import 'package:astra/features/scheduler/data/services/google_calendar_writer_service.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';

/// Fake implementation of auth.AuthClient backed by a customizable http request handler.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const writer = GoogleCalendarWriterService();

  group('GoogleCalendarWriterService Unit Tests (Phase 2X-3)', () {
    // A. Basic event: "Microsoft Interview" Monday 11:00, end absent -> default 1-hour duration
    test('A. Basic event: absent endTime defaults duration to exactly 1 hour', () async {
      late Map<String, dynamic> capturedBody;
      late String capturedMethod;
      late Uri capturedUri;

      final mockClient = MockAuthClient((request) async {
        capturedMethod = request.method;
        capturedUri = request.url;
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        final responseJson = jsonEncode({
          'id': 'test_event_1',
          'summary': capturedBody['summary'],
          'start': capturedBody['start'],
          'end': capturedBody['end'],
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseJson)),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final start = DateTime.utc(2026, 8, 17, 11, 0); // Monday 11:00 UTC
      final event = await writer.createEvent(
        mockClient,
        title: 'Microsoft Interview',
        startTime: start,
      );

      expect(capturedMethod, 'POST');
      expect(capturedUri.path, contains('/calendars/primary/events'));
      expect(capturedBody['summary'], 'Microsoft Interview');

      // Verify Start and End (1 hour duration)
      expect(capturedBody['start']['dateTime'], '2026-08-17T11:00:00.000Z');
      expect(capturedBody['end']['dateTime'], '2026-08-17T12:00:00.000Z');
      expect(event.id, 'test_event_1');
    });

    // B. Explicit end: start 11:00, end 12:30 -> exact duration preserved
    test('B. Explicit end: exact endTime is preserved', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_2'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final start = DateTime.utc(2026, 8, 17, 11, 0);
      final end = DateTime.utc(2026, 8, 17, 12, 30);

      await writer.createEvent(
        mockClient,
        title: 'Tech Screening',
        startTime: start,
        endTime: end,
      );

      expect(capturedBody['start']['dateTime'], '2026-08-17T11:00:00.000Z');
      expect(capturedBody['end']['dateTime'], '2026-08-17T12:30:00.000Z');
    });

    // C. Timezone: Asia/Kolkata correctly placed on start/end EventDateTime
    test('C. Timezone: Asia/Kolkata is specified on start and end EventDateTime', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_3'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final start = DateTime(2026, 8, 17, 11, 0);

      await writer.createEvent(
        mockClient,
        title: 'Local Meeting',
        startTime: start,
        timezone: 'Asia/Kolkata',
      );

      expect(capturedBody['start']['timeZone'], 'Asia/Kolkata');
      expect(capturedBody['end']['timeZone'], 'Asia/Kolkata');
    });

    // D. Description & Location: provided values reach event.description and event.location
    test('D. Description and location: supplied fields reach event', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_4'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final start = DateTime.utc(2026, 8, 17, 11, 0);

      await writer.createEvent(
        mockClient,
        title: 'Executive Briefing',
        startTime: start,
        description: 'Created via ASTRA Assistant.\nOrganization: Microsoft',
        location: 'Teams Meeting',
      );

      expect(capturedBody['description'], 'Created via ASTRA Assistant.\nOrganization: Microsoft');
      expect(capturedBody['location'], 'Teams Meeting');
    });

    // E. DAILY recurrence: RRULE:FREQ=DAILY
    test('E. DAILY recurrence: maps to RRULE:FREQ=DAILY', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_5'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        hour: 9,
        minute: 0,
      );

      await writer.createEvent(
        mockClient,
        title: 'Daily Standup',
        startTime: DateTime.utc(2026, 8, 17, 9, 0),
        recurrenceRule: rule,
      );

      expect(capturedBody['recurrence'], contains('RRULE:FREQ=DAILY'));
    });

    // F. WEEKDAYS recurrence: RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR
    test('F. WEEKDAYS recurrence: maps to RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_6'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        startDate: DateTime.utc(2026, 5, 25),
        endDate: DateTime.utc(2026, 6, 18, 13, 0),
        hour: 9,
        minute: 0,
      );

      await writer.createEvent(
        mockClient,
        title: 'Weekday Training',
        startTime: DateTime.utc(2026, 5, 25, 9, 0),
        recurrenceRule: rule,
      );

      final recurrenceList = capturedBody['recurrence'] as List;
      expect(recurrenceList.first, startsWith('RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'));
      expect(recurrenceList.first, contains('UNTIL=20260618T130000Z'));
    });

    // G. WEEKLY Monday: RRULE:FREQ=WEEKLY;BYDAY=MO
    test('G. WEEKLY Monday recurrence: maps to RRULE:FREQ=WEEKLY;BYDAY=MO', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_7'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byWeekdays: [DateTime.monday],
        hour: 11,
        minute: 0,
      );

      await writer.createEvent(
        mockClient,
        title: 'Weekly 1:1',
        startTime: DateTime.utc(2026, 8, 17, 11, 0),
        recurrenceRule: rule,
      );

      expect(capturedBody['recurrence'], contains('RRULE:FREQ=WEEKLY;BYDAY=MO'));
    });

    // H. MONTHLY 25th: RRULE:FREQ=MONTHLY;BYMONTHDAY=25
    test('H. MONTHLY 25th recurrence: maps to RRULE:FREQ=MONTHLY;BYMONTHDAY=25', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockAuthClient((request) async {
        final bodyBytes = await request.finalize().toBytes();
        capturedBody = jsonDecode(utf8.decode(bodyBytes)) as Map<String, dynamic>;

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'id': 'test_event_8'}))),
          200,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime.utc(2026, 8, 25),
        hour: 10,
        minute: 0,
      );

      await writer.createEvent(
        mockClient,
        title: 'Monthly Bill',
        startTime: DateTime.utc(2026, 8, 25, 10, 0),
        recurrenceRule: rule,
      );

      expect(capturedBody['recurrence'], contains('RRULE:FREQ=MONTHLY;BYMONTHDAY=25'));
    });

    // I. API error handling: 403 -> PERMISSION_REQUIRED
    test('I. API error handling: 403 status throws GoogleCalendarWriteErrorCode.permissionRequired', () async {
      final mockClient = MockAuthClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'error': {
              'code': 403,
              'message': 'Insufficient Permission',
            }
          }))),
          403,
          headers: {'content-type': 'application/json; charset=UTF-8'},
        );
      });

      expect(
        () => writer.createEvent(
          mockClient,
          title: 'Unauthorized Event',
          startTime: DateTime.now(),
        ),
        throwsA(
          isA<GoogleCalendarWriteException>().having(
            (e) => e.code,
            'code',
            GoogleCalendarWriteErrorCode.permissionRequired,
          ),
        ),
      );
    });

    // J. Network failure: SocketException -> NETWORK_ERROR
    test('J. Network failure: SocketException throws GoogleCalendarWriteErrorCode.networkError', () async {
      final mockClient = MockAuthClient((request) async {
        throw const SocketException('No route to host');
      });

      expect(
        () => writer.createEvent(
          mockClient,
          title: 'Offline Event',
          startTime: DateTime.now(),
        ),
        throwsA(
          isA<GoogleCalendarWriteException>().having(
            (e) => e.code,
            'code',
            GoogleCalendarWriteErrorCode.networkError,
          ),
        ),
      );
    });
  });
}
