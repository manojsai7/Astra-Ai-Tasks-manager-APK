import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/google_calendar_writer_provider.dart';
import 'package:astra/services/assistant/astra_document_analyzer.dart';
import 'package:astra/services/email/astra_email_analyzer.dart';
import 'package:astra/features/scheduler/data/services/gmail_sync_service.dart';
import 'package:astra/features/scheduler/data/services/google_calendar_writer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_mock_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA Part 7: Email & Document Candidate Card Google Calendar Integration Tests', () {
    late AppDatabase db;
    late MockAuthClient mockClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      mockClient = MockAuthClient((req) async {
        throw UnimplementedError();
      });
    });

    tearDown(() async {
      await db.close();
    });

    test('A. ADD TO CALENDAR with valid authenticated client calls writer once and reports success', () async {
      int writerCallCount = 0;
      String? capturedTitle;
      DateTime? capturedStart;
      DateTime? capturedEnd;

      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          writerCallCount++;
          capturedTitle = title;
          capturedStart = startTime;
          capturedEnd = endTime;
          return FakeTestCalendarEvent(id: 'google_event_123', summary: title);
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: mockClient)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final item = AstraDocumentItem(
        id: 'doc_item_aptitude_1',
        type: 'training',
        title: 'SBT Aptitude Training',
        description: 'Aptitude training (6 Days)',
        startAt: DateTime(2026, 8, 17, 9, 0),
        endAt: DateTime(2026, 8, 22, 17, 0),
        durationDays: 6,
        actionRequired: false,
        confidence: 0.98,
      );

      final notifier = container.read(assistantStateProvider.notifier);
      await notifier.addDocumentItemToCalendar(item);

      expect(writerCallCount, 1);
      expect(capturedTitle, 'SBT Aptitude Training');
      expect(capturedStart, DateTime(2026, 8, 17, 9, 0));
      expect(capturedEnd, DateTime(2026, 8, 22, 17, 0));

      final state = container.read(assistantStateProvider);
      expect(state.messages.last.text, contains('Added to Google Calendar'));

      // Also verify local task invariant was preserved
      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'SBT Aptitude Training');
      expect(tasks.first.startAt, DateTime(2026, 8, 17, 9, 0));
      expect(tasks.first.endAt, DateTime(2026, 8, 22, 17, 0));
    });

    test('B. No auth client shows permission error and does not call writer', () async {
      int writerCallCount = 0;
      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          writerCallCount++;
          return FakeTestCalendarEvent(id: 'event_x');
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: null)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final item = AstraDocumentItem(
        id: 'doc_item_noauth_1',
        type: 'meeting',
        title: 'Team Sync',
        description: 'Meeting',
        startAt: DateTime(2026, 8, 18, 10, 0),
        actionRequired: false,
        confidence: 0.95,
      );

      final notifier = container.read(assistantStateProvider.notifier);
      await notifier.addDocumentItemToCalendar(item);

      expect(writerCallCount, 0);
      final state = container.read(assistantStateProvider);
      expect(state.messages.last.text, contains('Google Calendar permission is required.'));
    });

    test('C. 403 / Permission Required exception shows permission error message', () async {
      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          throw const GoogleCalendarWriteException(
            code: GoogleCalendarWriteErrorCode.permissionRequired,
            message: 'Insufficient Calendar permissions.',
          );
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: mockClient)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final item = AstraDocumentItem(
        id: 'doc_item_403_1',
        type: 'exam',
        title: 'Placement Assessment',
        description: 'Assessment',
        startAt: DateTime(2026, 8, 19, 14, 0),
        actionRequired: true,
        confidence: 0.95,
      );

      final notifier = container.read(assistantStateProvider.notifier);
      await notifier.addDocumentItemToCalendar(item);

      final state = container.read(assistantStateProvider);
      expect(state.messages.last.text, 'Google Calendar permission is required.');
    });

    test('D. Network failure shows temporarily unavailable error message', () async {
      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          throw const GoogleCalendarWriteException(
            code: GoogleCalendarWriteErrorCode.networkError,
            message: 'SocketException: failed host lookup',
          );
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: mockClient)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final item = AstraDocumentItem(
        id: 'doc_item_net_1',
        type: 'interview',
        title: 'Google Technical Interview',
        description: 'Tech Round',
        startAt: DateTime(2026, 8, 20, 11, 0),
        actionRequired: true,
        confidence: 0.99,
      );

      final notifier = container.read(assistantStateProvider.notifier);
      await notifier.addDocumentItemToCalendar(item);

      final state = container.read(assistantStateProvider);
      expect(state.messages.last.text, 'Google Calendar is temporarily unavailable.');
    });

    test('E. Duration event preserves exact startAt and endAt for multi-day events', () async {
      DateTime? capturedStart;
      DateTime? capturedEnd;

      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          capturedStart = startTime;
          capturedEnd = endTime;
          return FakeTestCalendarEvent(id: 'google_event_fullstack', summary: title);
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: mockClient)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final item = AstraDocumentItem(
        id: 'doc_item_fullstack_8d',
        type: 'training',
        title: 'SBT Fullstack Training',
        description: 'Fullstack track (8 Days)',
        startAt: DateTime(2026, 8, 17, 9, 0),
        endAt: DateTime(2026, 8, 25, 17, 0),
        durationDays: 8,
        actionRequired: false,
        confidence: 0.98,
      );

      final notifier = container.read(assistantStateProvider.notifier);
      await notifier.addDocumentItemToCalendar(item);

      expect(capturedStart, DateTime(2026, 8, 17, 9, 0));
      expect(capturedEnd, DateTime(2026, 8, 25, 17, 0));
    });

    test('F. Double tap / repeated invocation prevents duplicate Google Calendar insertions', () async {
      int writerCallCount = 0;

      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          writerCallCount++;
          return FakeTestCalendarEvent(id: 'event_dup_$writerCallCount');
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: mockClient)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final item = AstraDocumentItem(
        id: 'doc_item_single_tap_1',
        type: 'meeting',
        title: 'Project Kickoff',
        description: 'Kickoff meeting',
        startAt: DateTime(2026, 8, 21, 15, 0),
        actionRequired: false,
        confidence: 0.95,
      );

      final notifier = container.read(assistantStateProvider.notifier);

      // Tap 1
      await notifier.addDocumentItemToCalendar(item);
      // Tap 2 (repeated)
      await notifier.addDocumentItemToCalendar(item);

      expect(writerCallCount, 1);
    });

    test('G. Email Insight Card ADD TO CALENDAR uses authoritative path and preserves local task', () async {
      int writerCallCount = 0;
      String? capturedTitle;

      final writerService = MockGoogleCalendarWriterService(
        (client, {required title, required startTime, endTime, description, location, timezone = 'Asia/Kolkata', recurrenceRule}) async {
          writerCallCount++;
          capturedTitle = title;
          return FakeTestCalendarEvent(id: 'email_gcal_1', summary: title);
        },
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          googleAuthServiceProvider.overrideWithValue(MockGoogleAuthService(clientToReturn: mockClient)),
          googleCalendarWriterServiceProvider.overrideWithValue(writerService),
        ],
      );

      final email = GmailMessageData(
        id: 'msg_hackathon_1',
        subject: 'National Hackathon Registration & Opening Ceremony',
        sender: 'hackathon@tech.org',
        senderName: 'Hackathon Org',
        senderEmail: 'hackathon@tech.org',
        date: DateTime(2026, 8, 16, 10, 0),
        snippet: 'Opening ceremony is scheduled on 24 Aug 2026 at 10:00 AM.',
        bodyText: 'Opening ceremony is scheduled on 24 Aug 2026 at 10:00 AM.',
      );

      final analysis = AstraEmailAnalysis(
        suggestedTaskTitle: 'Hackathon Opening Ceremony',
        category: EmailCategory.important,
        importance: EmailImportance.high,
        isActionable: true,
        isEvent: true,
        eventDateTime: DateTime(2026, 8, 24, 10, 0),
        startAt: DateTime(2026, 8, 24, 10, 0),
        endAt: DateTime(2026, 8, 24, 12, 0),
        organization: 'Tech Org',
      );

      final notifier = container.read(assistantStateProvider.notifier);
      await notifier.addEmailInsightToCalendar(email: email, analysis: analysis);

      expect(writerCallCount, 1);
      expect(capturedTitle, 'Hackathon Opening Ceremony');

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Hackathon Opening Ceremony');
    });
  });
}
