import 'package:flutter_test/flutter_test.dart';
import 'package:astra/services/assistant/astra_input_classifier.dart';
import 'package:astra/services/assistant/astra_document_analyzer.dart';
import 'package:astra/services/email/astra_email_analyzer.dart';
import 'package:astra/features/scheduler/data/services/gmail_sync_service.dart';

void main() {
  group('ASTRA Part A & B: Long-Form Input Classification & Document Analyzer Tests', () {
    const classifier = AstraInputClassifier();
    const analyzer = AstraDocumentAnalyzer();

    const sampleNotice = '''Dear students
I would like to inform you regarding the GB 2027 Batch students and the final phase of SBT training is going to start from 17-08-2026 to 22-08-2026(6 Days) for Apptitude and 17-08-2026 to 25-08-2026(8 days) for Fullstack. We have already shared a form in the respective groups. Therefore I request you all to respond to the form immediately, before today evening.''';

    test('1. Short command vs Long document classification', () {
      final cmd1 = classifier.classify('remind me to call Mom at 5pm');
      expect(cmd1.kind, AstraInputKind.command);

      final cmd2 = classifier.classify('move my exam to tomorrow at 7pm');
      expect(cmd2.kind, AstraInputKind.command);

      final conv = classifier.classify('What is the theory of relativity?');
      expect(conv.kind, AstraInputKind.conversation);

      final doc = classifier.classify(sampleNotice);
      expect(doc.kind, AstraInputKind.multiItemDocument);
      expect(doc.dateRangeCount, greaterThanOrEqualTo(2));
      expect(doc.hasEmailOrNoticeStructure, isTrue);
    });

    test('2. Single date extraction', () {
      final text = 'Please submit the assignment on 20-08-2026 before 5pm.';
      final result = analyzer.analyze(text, now: DateTime(2026, 8, 16, 10, 0));

      expect(result.extractedItems, isNotEmpty);
    });

    test('3. Single date-range extraction', () {
      final text = 'SBT Aptitude training starts from 17-08-2026 to 22-08-2026 (6 Days).';
      final result = analyzer.analyze(text, now: DateTime(2026, 8, 16, 10, 0));

      expect(result.extractedItems.length, 1);
      final item = result.extractedItems.first;
      expect(item.type, 'training');
      expect(item.startAt, isNotNull);
      expect(item.startAt!.year, 2026);
      expect(item.startAt!.month, 8);
      expect(item.startAt!.day, 17);
      expect(item.endAt, isNotNull);
      expect(item.endAt!.day, 22);
      expect(item.durationDays, 6);
      expect(item.isDuration, isTrue);
      expect(item.isDeadline, isFalse);
    });

    test('4. Multiple date ranges and multi-track training extraction', () {
      final result = analyzer.analyze(sampleNotice, now: DateTime(2026, 8, 16, 10, 0));

      // Must extract at least 3 distinct candidate items (Track 1, Track 2, and Form deadline)
      expect(result.extractedItems.length, greaterThanOrEqualTo(3));

      final aptitudeTrack = result.extractedItems.firstWhere((i) => i.title.toLowerCase().contains('aptitude'));
      expect(aptitudeTrack.startAt, DateTime(2026, 8, 17, 9, 0));
      expect(aptitudeTrack.endAt, DateTime(2026, 8, 22, 17, 0));
      expect(aptitudeTrack.durationDays, 6);
      expect(aptitudeTrack.isDuration, isTrue);

      final fullstackTrack = result.extractedItems.firstWhere((i) => i.title.toLowerCase().contains('fullstack'));
      expect(fullstackTrack.startAt, DateTime(2026, 8, 17, 9, 0));
      expect(fullstackTrack.endAt, DateTime(2026, 8, 25, 17, 0));
      expect(fullstackTrack.durationDays, 8);
      expect(fullstackTrack.isDuration, isTrue);
    });

    test('5. Action item and deadline extraction ("respond before today evening")', () {
      final result = analyzer.analyze(sampleNotice, now: DateTime(2026, 8, 16, 10, 0));

      final formItem = result.extractedItems.firstWhere((i) => i.type == 'form' || i.actionRequired);
      expect(formItem.actionRequired, isTrue);
      expect(formItem.dueAt, isNotNull);
      expect(formItem.dueAt!.day, 16);
      expect(formItem.dueAt!.hour, 18);
      expect(formItem.isDeadline, isTrue);
      expect(formItem.isDuration, isFalse);
    });

    test('6. Real-world sample email intake integration', () {
      final emailData = GmailMessageData(
        id: 'msg_gb2027_1',
        threadId: 'th_1',
        sender: 'Placement Cell <placements@college.edu>',
        senderName: 'Placement Cell',
        senderEmail: 'placements@college.edu',
        subject: 'GB 2027 Batch - SBT Training Schedule & Form Notice',
        snippet: 'Dear students I would like to inform you regarding...',
        bodyText: sampleNotice,
        date: DateTime(2026, 8, 16, 9, 30),
      );

      const emailAnalyzer = AstraEmailAnalyzer();
      final analysis = emailAnalyzer.analyze(emailData, referenceTime: DateTime(2026, 8, 16, 10, 0));

      expect(analysis.isActionable, isTrue);
      expect(analysis.documentAnalysis, isNotNull);
      expect(analysis.documentAnalysis!.extractedItems.length, greaterThanOrEqualTo(3));
    });
  });
}
