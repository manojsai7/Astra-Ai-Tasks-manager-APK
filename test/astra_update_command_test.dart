import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/assistant/astra_update_command.dart';

void main() {
  const parser = AstraUpdateParser();
  final refTime = DateTime(2026, 8, 15, 10, 0); // Saturday, Aug 15, 2026, 10:00 AM

  group('AstraUpdateParser Unit & Safety Tests (Phase 2Y-3)', () {
    // A. "move my exam to tomorrow at 7pm"
    test('A. "move my exam to tomorrow at 7pm" resolves target and due date', () {
      final cmd = parser.parse(
        text: 'move my exam to tomorrow at 7pm',
        now: refTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.newDueAt, DateTime(2026, 8, 16, 19, 0));
      expect(cmd.requiresConfirmation, isFalse);
      expect(cmd.hasChanges, isTrue);
    });

    // B. "reschedule my Microsoft interview to 2pm"
    test('B. "reschedule my Microsoft interview to 2pm" resolves target and time', () {
      final cmd = parser.parse(
        text: 'reschedule my Microsoft interview to 2pm',
        now: refTime,
      );

      expect(cmd.targetQuery, 'Microsoft interview');
      expect(cmd.newDueAt, DateTime(2026, 8, 15, 14, 0));
      expect(cmd.requiresConfirmation, isFalse);
      expect(cmd.hasChanges, isTrue);
    });

    // C. "change my assignment deadline to Friday"
    test('C. "change my assignment deadline to Friday" resolves target and date', () {
      final cmd = parser.parse(
        text: 'change my assignment deadline to Friday',
        now: refTime,
      );

      expect(cmd.targetQuery, 'assignment');
      expect(cmd.newDueAt, isNotNull);
      expect(cmd.newDueAt!.weekday, DateTime.friday);
      expect(cmd.requiresConfirmation, isFalse);
      expect(cmd.hasChanges, isTrue);
    });

    // D. "make the interview high priority"
    test('D. "make the interview high priority" resolves priority', () {
      final cmd = parser.parse(
        text: 'make the interview high priority',
        now: refTime,
      );

      expect(cmd.targetQuery, 'interview');
      expect(cmd.newPriority, 'high');
      expect(cmd.requiresConfirmation, isFalse);
      expect(cmd.hasChanges, isTrue);
    });

    // E. "rename my exam to physics exam"
    test('E. "rename my exam to physics exam" resolves new title', () {
      final cmd = parser.parse(
        text: 'rename my exam to physics exam',
        now: refTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.newTitle, 'Physics Exam');
      expect(cmd.requiresConfirmation, isFalse);
      expect(cmd.hasChanges, isTrue);
    });

    // F. "move my exam" -> missing new value -> requires confirmation
    test('F. "move my exam" requires confirmation when time is missing', () {
      final cmd = parser.parse(
        text: 'move my exam',
        now: refTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.newDueAt, isNull);
      expect(cmd.requiresConfirmation, isTrue);
      expect(cmd.warnings, isNotEmpty);
    });

    // G. "update my task" -> targetQuery missing -> requires confirmation
    test('G. "update my task" requires confirmation when target is missing', () {
      final cmd = parser.parse(
        text: 'update my task',
        now: refTime,
      );

      expect(cmd.targetQuery, isEmpty);
      expect(cmd.requiresConfirmation, isTrue);
      expect(cmd.warnings, contains('Which task would you like to update?'));
    });

    // H. "move my exam to tomorrow by 5" -> ambiguous time -> requires confirmation
    test('H. "move my exam to tomorrow by 5" triggers confirmation due to ambiguous time', () {
      final cmd = parser.parse(
        text: 'move my exam to tomorrow by 5',
        now: refTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.requiresConfirmation, isTrue);
      expect(cmd.newDueAt, isNull);
    });

    // I. Unknown priority should not crash or corrupt command
    test('I. Unknown priority should not crash parser', () {
      final cmd = parser.parse(
        text: 'make my task super-duper priority',
        now: refTime,
      );

      expect(cmd.requiresConfirmation, isTrue);
      expect(cmd.newPriority, isNull);
    });

    // K. "move my tomorrow exam to 7pm" -> targetQuery = "exam", tomorrow 19:00
    test('K. "move my tomorrow exam to 7pm" extracts target exam and resolves tomorrow 7pm', () {
      final cmd = parser.parse(
        text: 'move my tomorrow exam to 7pm',
        now: refTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.newDueAt, DateTime(2026, 8, 16, 19, 0));
      expect(cmd.requiresConfirmation, isFalse);
    });

    // L. "move my exam to 7pm" when today 9pm -> confirmation warning
    test('L. "move my exam to 7pm" when today is 9pm triggers past-time confirmation', () {
      final nightTime = DateTime(2026, 8, 15, 21, 0); // 9:00 PM
      final cmd = parser.parse(
        text: 'move my exam to 7pm',
        now: nightTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.requiresConfirmation, isTrue);
      expect(cmd.warnings.any((w) => w.contains('already passed')), isTrue);
    });

    // M. "move my exam to tomorrow" -> missing time -> confirmation
    test('M. "move my exam to tomorrow" triggers confirmation due to missing time', () {
      final cmd = parser.parse(
        text: 'move my exam to tomorrow',
        now: refTime,
      );

      expect(cmd.targetQuery, 'exam');
      expect(cmd.requiresConfirmation, isTrue);
    });
  });
}
