import 'package:flutter_test/flutter_test.dart';

import 'package:astra/models/task.dart';
import 'package:astra/services/assistant/astra_task_resolver.dart';

void main() {
  const resolver = AstraTaskResolver();

  final task1 = Task(
    id: 't1',
    title: 'Microsoft Interview',
    organization: 'Microsoft',
    dueDate: DateTime(2026, 8, 17, 11, 0),
    priority: 'high',
    status: 'active',
    createdAt: DateTime(2026, 8, 15),
  );

  final task2 = Task(
    id: 't2',
    title: 'Physics Exam',
    organization: null,
    dueDate: DateTime(2026, 8, 18, 14, 0),
    priority: 'urgent',
    status: 'active',
    createdAt: DateTime(2026, 8, 15),
  );

  final task3 = Task(
    id: 't3',
    title: 'Maths Exam',
    organization: null,
    dueDate: DateTime(2026, 8, 19, 10, 0),
    priority: 'medium',
    status: 'active',
    createdAt: DateTime(2026, 8, 15),
  );

  final task4 = Task(
    id: 't4',
    title: 'Submit Assignment',
    organization: null,
    dueDate: DateTime(2026, 8, 20, 17, 0),
    priority: 'medium',
    status: 'active',
    createdAt: DateTime(2026, 8, 15),
  );

  final completedTask = Task(
    id: 't_completed',
    title: 'Old History Exam',
    organization: null,
    dueDate: DateTime(2026, 8, 10),
    priority: 'low',
    status: 'completed',
    completedAt: DateTime(2026, 8, 10),
    createdAt: DateTime(2026, 8, 5),
  );

  final standardTaskList = [task1, task2, task3, task4, completedTask];

  group('AstraTaskResolver Unit & Safety Tests (Phase 2Y-2)', () {
    // A. Exact title
    test('A. Exact title: "Microsoft Interview" -> exact Microsoft Interview', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'Microsoft Interview');
      expect(result.isExact, isTrue);
      expect(result.task!.id, 't1');
      expect(result.task!.title, 'Microsoft Interview');
    });

    // B. Case-insensitive
    test('B. Case-insensitive: "mIcRoSoFt interview" -> exact Microsoft Interview', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'mIcRoSoFt interview');
      expect(result.isExact, isTrue);
      expect(result.task!.id, 't1');
    });

    // C. Stopword cleanup: "my assignment" or "the assignment" -> exact Submit Assignment
    test('C. Stopword cleanup: "my assignment" -> exact Submit Assignment', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'my assignment');
      expect(result.isExact, isTrue);
      expect(result.task!.id, 't4');
    });

    // D. Organization matching: "Microsoft" -> Microsoft Interview
    test('D. Organization matching: "Microsoft" -> exact Microsoft Interview', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'Microsoft');
      expect(result.isExact, isTrue);
      expect(result.task!.id, 't1');
    });

    // E. Multiple matches: "exam" matches both Physics Exam and Maths Exam -> ambiguous
    test('E. Multiple matches: "exam" matches both Physics and Maths exam -> ambiguous', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'exam');
      expect(result.isAmbiguous, isTrue);
      expect(result.candidates.length, 2);
      final titles = result.candidates.map((t) => t.title).toList();
      expect(titles, contains('Physics Exam'));
      expect(titles, contains('Maths Exam'));
    });

    // F. No match: "groceries" when not present -> notFound
    test('F. No match: "buy groceries" -> notFound', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'buy groceries');
      expect(result.isNotFound, isTrue);
      expect(result.task, isNull);
    });

    // G. Positional: "task 1", "task 2", "third task"
    test('G. Positional: "task 1" and "second task" map to exact active indices', () {
      final res1 = resolver.resolve(tasks: standardTaskList, query: 'task 1');
      expect(res1.isExact, isTrue);
      expect(res1.task!.id, 't1'); // First active task

      final res2 = resolver.resolve(tasks: standardTaskList, query: 'second task');
      expect(res2.isExact, isTrue);
      expect(res2.task!.id, 't2'); // Second active task

      final res3 = resolver.resolve(tasks: standardTaskList, query: '3rd');
      expect(res3.isExact, isTrue);
      expect(res3.task!.id, 't3'); // Third active task
    });

    // H. Out-of-range positional reference: "task 99" -> notFound
    test('H. Out-of-range positional reference: "task 99" -> notFound', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'task 99');
      expect(result.isNotFound, isTrue);
    });

    // I. Completed task exclusion: Completed task is never matched
    test('I. Completed task exclusion: "History Exam" matches only completed task -> notFound', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'History Exam');
      expect(result.isNotFound, isTrue);
    });

    // J. Never fallback to first task: unknown query with tasks present -> notFound, never exact(first)
    test('J. CRITICAL SAFETY INVARIANT: Unknown query NEVER falls back to tasks.first', () {
      final result = resolver.resolve(tasks: standardTaskList, query: 'quantum physics lab report');
      expect(result.isNotFound, isTrue);
      expect(result.task, isNull);
      expect(result.isExact, isFalse);
    });
  });
}
