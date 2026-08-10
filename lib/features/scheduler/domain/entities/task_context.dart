/// Domain entity representing extra AI context associated with a Task
/// (e.g. parsed from Gmail emails or Google Calendar events).
class TaskContext {
  final int? id;
  final String taskId;
  final String? companyName;
  final String? role;
  final String? requirements;
  final String? applicationLink;
  final String? emailSnippet;
  final String? fullEmail;
  final bool hasApplied;
  final DateTime? appliedAt;
  final String? eventType; // e.g. 'exam', 'application', 'meeting', 'reminder'
  final String? location;
  final String? stipend;
  final String? actionItems;
  final String source; // 'gmail', 'calendar', 'manual'

  const TaskContext({
    this.id,
    required this.taskId,
    this.companyName,
    this.role,
    this.requirements,
    this.applicationLink,
    this.emailSnippet,
    this.fullEmail,
    this.hasApplied = false,
    this.appliedAt,
    this.eventType,
    this.location,
    this.stipend,
    this.actionItems,
    this.source = 'gmail',
  });

  TaskContext copyWith({
    int? id,
    String? taskId,
    String? companyName,
    String? role,
    String? requirements,
    String? applicationLink,
    String? emailSnippet,
    String? fullEmail,
    bool? hasApplied,
    DateTime? appliedAt,
    String? eventType,
    String? location,
    String? stipend,
    String? actionItems,
    String? source,
  }) {
    return TaskContext(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      requirements: requirements ?? this.requirements,
      applicationLink: applicationLink ?? this.applicationLink,
      emailSnippet: emailSnippet ?? this.emailSnippet,
      fullEmail: fullEmail ?? this.fullEmail,
      hasApplied: hasApplied ?? this.hasApplied,
      appliedAt: appliedAt ?? this.appliedAt,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      stipend: stipend ?? this.stipend,
      actionItems: actionItems ?? this.actionItems,
      source: source ?? this.source,
    );
  }
}
