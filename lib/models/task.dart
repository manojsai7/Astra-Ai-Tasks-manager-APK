class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high'
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'])
            : null,
        priority: json['priority'] ?? 'medium',
        isCompleted: json['isCompleted'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
