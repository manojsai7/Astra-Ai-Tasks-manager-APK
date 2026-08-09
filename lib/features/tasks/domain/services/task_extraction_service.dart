import '../entities/task_extraction_proposal.dart';

/// Contract representing the service used to extract tasks from raw text.
///
/// Implementations could call remote Gemini/Supabase backend services or
/// return mock data locally.
abstract interface class TaskExtractionService {
  /// Analyzes the [rawText] using AI and returns a structured task proposal.
  ///
  /// The [referenceTime] provides contextual temporal coordinates (e.g., today's date)
  /// so that relative time expressions like "tomorrow" can be parsed contextually.
  Future<TaskExtractionProposal> extractTask(
    String rawText,
    DateTime referenceTime,
  );
}
