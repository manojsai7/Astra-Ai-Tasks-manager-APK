import '../../domain/entities/task_context.dart';
import '../../../../features/tasks/domain/entities/task.dart';
import '../../../../core/network/astra_ai_gateway.dart';

/// Structured result returned after AI context extraction.
class ExtractedTaskWithContext {
  final bool isTask;
  final String title;
  final String? description;
  final TaskType taskType;
  final TaskPriority priority;
  final DateTime? dueAt;
  final TaskContext context;

  ExtractedTaskWithContext({
    required this.isTask,
    required this.title,
    this.description,
    required this.taskType,
    required this.priority,
    this.dueAt,
    required this.context,
  });
}

/// Service that parses email content or calendar text using ASTRA's AI gateway.
/// to extract structured task & full contextual details.
class GeminiContextExtractor {
  GeminiContextExtractor({AstraAiGateway? gateway}) : _gateway = gateway ?? AstraAiGateway();

  final AstraAiGateway _gateway;

  /// Extracts task details from user prompt text.
  Future<ExtractedTaskWithContext> extractFromUserPrompt(String promptText) async {
    try {
      final json = await _gateway.extractTask(text: promptText, source: 'prompt');
      return _mapJsonToExtractedResult(
        json: json,
        taskId: DateTime.now().millisecondsSinceEpoch.toString(),
        fullEmail: promptText,
        snippet: promptText,
        source: 'prompt',
      );
    } catch (_) {
      // A deterministic fallback retains task capture when the gateway is unavailable.
    }

    return _heuristicExtraction(
      subject: promptText,
      sender: 'User',
      body: promptText,
      taskId: DateTime.now().millisecondsSinceEpoch.toString(),
      source: 'prompt',
    );
  }

  /// Extracts task details and rich context from raw email text.
  Future<ExtractedTaskWithContext> extractFromEmail({
    required String emailSubject,
    required String emailSender,
    required String emailBody,
    required String messageId,
  }) async {
    try {
      final json = await _gateway.extractTask(
        text: 'Subject: $emailSubject\nFrom: $emailSender\n\n$emailBody',
        source: 'gmail',
      );
      return _mapJsonToExtractedResult(
        json: json,
        taskId: messageId,
        fullEmail: emailBody,
        snippet: emailSubject,
        source: 'gmail',
      );
    } catch (_) {
      // Fall through to deterministic extraction when the gateway is unavailable.
    }

    return _heuristicExtraction(
      subject: emailSubject,
      sender: emailSender,
      body: emailBody,
      taskId: messageId,
      source: 'gmail',
    );
  }

  /// Extracts task details from Google Calendar event description.
  Future<ExtractedTaskWithContext> extractFromCalendar({
    required String eventTitle,
    required String? description,
    required String? location,
    required DateTime startTime,
    required String eventId,
    required String? htmlLink,
  }) async {
    final lowerTitle = eventTitle.toLowerCase();
    TaskType taskType = TaskType.event;
    if (lowerTitle.contains('exam') || lowerTitle.contains('test') || lowerTitle.contains('quiz')) {
      taskType = TaskType.reminder;
    } else if (lowerTitle.contains('interview') || lowerTitle.contains('apply') || lowerTitle.contains('application')) {
      taskType = TaskType.application;
    }

    final context = TaskContext(
      taskId: eventId,
      companyName: _extractCompanyName(eventTitle),
      role: eventTitle,
      requirements: description,
      applicationLink: htmlLink,
      emailSnippet: description != null && description.length > 100
          ? '${description.substring(0, 100)}...'
          : description,
      fullEmail: description,
      eventType: taskType.name,
      location: location,
      source: 'calendar',
    );

    return ExtractedTaskWithContext(
      isTask: true,
      title: eventTitle,
      description: description,
      taskType: taskType,
      priority: TaskPriority.high,
      dueAt: startTime,
      context: context,
    );
  }

  ExtractedTaskWithContext _mapJsonToExtractedResult({
    required Map<String, dynamic> json,
    required String taskId,
    required String fullEmail,
    required String snippet,
    required String source,
  }) {
    final isTask = json['is_task'] == true;
    final title = json['title'] as String? ?? snippet;
    final eventTypeStr = (json['event_type'] as String? ?? 'application').toLowerCase();
    
    TaskType taskType = TaskType.application;
    if (eventTypeStr == 'exam' || eventTypeStr == 'test') {
      taskType = TaskType.reminder;
    } else if (eventTypeStr == 'meeting') {
      taskType = TaskType.event;
    } else if (eventTypeStr == 'reminder') {
      taskType = TaskType.reminder;
    }

    final priorityStr = (json['priority'] as String? ?? 'MEDIUM').toUpperCase();
    TaskPriority priority = TaskPriority.fromValue(priorityStr);

    DateTime? dueAt;
    if (json['deadline'] != null) {
      try {
        dueAt = DateTime.parse(json['deadline']);
      } catch (_) {}
    }

    final context = TaskContext(
      taskId: taskId,
      companyName: json['company_name'] as String?,
      role: json['role'] as String?,
      requirements: json['requirements'] as String?,
      applicationLink: json['application_link'] as String?,
      emailSnippet: snippet,
      fullEmail: fullEmail,
      eventType: eventTypeStr,
      location: json['location'] as String?,
      stipend: json['stipend'] as String?,
      actionItems: json['action_items'] as String?,
      source: source,
    );

    return ExtractedTaskWithContext(
      isTask: isTask,
      title: title,
      description: json['action_items'] as String? ?? snippet,
      taskType: taskType,
      priority: priority,
      dueAt: dueAt,
      context: context,
    );
  }

  ExtractedTaskWithContext _heuristicExtraction({
    required String subject,
    required String sender,
    required String body,
    required String taskId,
    required String source,
  }) {
    final text = '$subject\n$body';
    final lower = text.toLowerCase();

    String? company = _extractCompanyName(subject) ?? _extractCompanyName(sender);
    String? link = _extractUrl(body);

    TaskType type = TaskType.application;
    String eventType = 'application';
    if (lower.contains('exam') || lower.contains('test') || lower.contains('midterm') || lower.contains('quiz')) {
      type = TaskType.reminder;
      eventType = 'exam';
    } else if (lower.contains('interview') || lower.contains('assessment')) {
      type = TaskType.application;
      eventType = 'application';
    }

    // Attempt date extraction
    DateTime? dueAt = _extractDate(body) ?? DateTime.now().add(const Duration(days: 3));

    final context = TaskContext(
      taskId: taskId,
      companyName: company,
      role: subject,
      requirements: body.length > 300 ? '${body.substring(0, 300)}...' : body,
      applicationLink: link,
      emailSnippet: subject,
      fullEmail: body,
      eventType: eventType,
      source: source,
    );

    return ExtractedTaskWithContext(
      isTask: true,
      title: subject,
      description: 'Extracted from $sender',
      taskType: type,
      priority: TaskPriority.high,
      dueAt: dueAt,
      context: context,
    );
  }

  String? _extractCompanyName(String text) {
    final words = ['Amazon', 'Google', 'Microsoft', 'Meta', 'Apple', 'Flipkart', 'Uber', 'Goldman Sachs', 'JPMorgan', 'Adobe', 'TCS', 'Infosys', 'Wipro'];
    for (final w in words) {
      if (text.toLowerCase().contains(w.toLowerCase())) return w;
    }
    return null;
  }

  String? _extractUrl(String text) {
    final regExp = RegExp(r'https?://[^\s<>"]+');
    final match = regExp.firstMatch(text);
    return match?.group(0);
  }

  DateTime? _extractDate(String text) {
    // Basic date matcher for YYYY-MM-DD or DD/MM/YYYY
    final isoExp = RegExp(r'\b20\d{2}[-/]\d{1,2}[-/]\d{1,2}\b');
    final match = isoExp.firstMatch(text);
    if (match != null) {
      try {
        return DateTime.parse(match.group(0)!.replaceAll('/', '-'));
      } catch (_) {}
    }
    return null;
  }
}
