/// Structured assistant response — no raw markdown in the UI layer.
enum AstraResponseType {
  text,
  taskCreated,
  taskCompleted,
  taskList,
  taskQuery,
  reminderCancelled,
  reminderSnoozed,
  info,
  success,
  error,
  auth,
  syncResult,
  emailSummary,
  calendarSummary,
}

class AstraResponseLine {
  final String label;
  final String value;
  final bool highlight;

  const AstraResponseLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

class AstraAction {
  final String id;
  final String label;

  const AstraAction({required this.id, required this.label});
}

class AstraResponse {
  final AstraResponseType type;
  final String headline;
  final List<AstraResponseLine> lines;
  final List<AstraAction> actions;
  final Map<String, dynamic>? data;

  const AstraResponse({
    required this.type,
    required this.headline,
    this.lines = const [],
    this.actions = const [],
    this.data,
  });

  /// Plain text for copy-to-clipboard — no markdown artifacts.
  String toPlainText() {
    final buf = StringBuffer(headline);
    for (final line in lines) {
      buf.writeln();
      if (line.label.isNotEmpty) {
        buf.write('${line.label}: ${line.value}');
      } else {
        buf.write(line.value);
      }
    }
    return buf.toString().trim();
  }
}
