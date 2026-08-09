import '../../domain/entities/task.dart';
import '../../domain/entities/task_extraction_proposal.dart';
import '../../domain/services/task_extraction_service.dart';

/// Local fake implementation of [TaskExtractionService] for development and testing.
///
/// Returns deterministic task proposals based on keywords in the input raw text.
class FakeTaskExtractionService implements TaskExtractionService {
  @override
  Future<TaskExtractionProposal> extractTask(
    String rawText,
    DateTime referenceTime,
  ) async {
    // Simulate slight async network delay
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final normalized = rawText.toLowerCase();

    if (normalized.contains('amazon')) {
      return const TaskExtractionProposal(
        title: 'Apply for Amazon SDE Internship',
        description: 'Amazon is hiring for SDE interns. Apply before 20 July.',
        taskType: TaskType.application,
        priority: TaskPriority.high,
        dateExpression: '20 July',
        timeExpression: null,
        confidence: 0.95,
        requiresReview: false,
      );
    } else if (normalized.contains('tomorrow')) {
      return const TaskExtractionProposal(
        title: 'Submit project report',
        description: 'Report is due tomorrow at 2 PM',
        taskType: TaskType.todo,
        priority: TaskPriority.high,
        dateExpression: 'tomorrow',
        timeExpression: '2:00 PM',
        confidence: 0.9,
        requiresReview: false,
      );
    } else if (normalized.contains('today')) {
      return const TaskExtractionProposal(
        title: 'Call mom',
        description: 'Call mom today',
        taskType: TaskType.todo,
        priority: TaskPriority.medium,
        dateExpression: 'today',
        timeExpression: null,
        confidence: 0.95,
        requiresReview: false,
      );
    } else if (normalized.contains('ambiguous')) {
      return const TaskExtractionProposal(
        title: 'Vague request task',
        description: 'Let us meet some day next week',
        taskType: TaskType.event,
        priority: TaskPriority.low,
        dateExpression: 'some day next week',
        timeExpression: null,
        confidence: 0.5,
        requiresReview: true,
        uncertaintyReason: 'Date expression "some day next week" is too vague.',
      );
    } else if (normalized.contains('empty title')) {
      return const TaskExtractionProposal(
        title: '',
        description: 'Raw text has no title',
        taskType: TaskType.todo,
        priority: TaskPriority.medium,
        dateExpression: null,
        timeExpression: null,
        confidence: 0.3,
        requiresReview: true,
        uncertaintyReason: 'Unable to extract a meaningful task title.',
      );
    } else {
      // Default fallback proposal
      return TaskExtractionProposal(
        title: rawText.length > 30 ? '${rawText.substring(0, 27)}...' : rawText,
        description: rawText,
        taskType: TaskType.todo,
        priority: TaskPriority.medium,
        dateExpression: null,
        timeExpression: null,
        confidence: 0.7,
        requiresReview: true,
        uncertaintyReason: 'Unrecognized pattern. Manual review required.',
      );
    }
  }
}
