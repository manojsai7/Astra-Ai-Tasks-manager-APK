import 'package:intl/intl.dart';

import '../reminders/reminder.dart';
import 'astra_response.dart';

/// Builds structured [AstraResponse] objects for the chat UI.
class AstraResponseBuilder {
  static AstraResponse taskCreated({
    required String title,
    DateTime? dueAt,
    String? timezone,
    String? organization,
    String priority = 'medium',
    ScheduleOutcome? notificationOutcome,
    String? calendarStatus,
    String? taskId,
    List<String> subtasks = const [],
  }) {
    final lines = <AstraResponseLine>[
      AstraResponseLine(label: '', value: title, highlight: true),
    ];

    if (dueAt != null) {
      lines.add(AstraResponseLine(
        label: 'Reminder',
        value: DateFormat('EEE, MMM d · h:mm a').format(dueAt),
      ));
    }
    if (timezone != null) {
      lines.add(AstraResponseLine(label: 'Timezone', value: timezone));
    }
    if (organization != null) {
      lines.add(AstraResponseLine(label: 'Organization', value: organization));
    }
    lines.add(AstraResponseLine(label: 'Priority', value: priority.toUpperCase()));

    if (calendarStatus != null && calendarStatus.isNotEmpty) {
      lines.add(AstraResponseLine(label: 'Calendar', value: calendarStatus));
    }

    if (notificationOutcome != null) {
      lines.add(AstraResponseLine(
        label: 'Notification',
        value: _notificationLabel(notificationOutcome),
      ));
    }

    for (final sub in subtasks) {
      lines.add(AstraResponseLine(label: 'Subtask', value: sub));
    }

    return AstraResponse(
      type: AstraResponseType.taskCreated,
      headline: 'Task created',
      lines: lines,
      actions: taskId != null
          ? [
              AstraAction(id: 'complete_$taskId', label: 'DONE'),
              AstraAction(id: 'snooze_$taskId', label: 'SNOOZE 10m'),
            ]
          : const [],
      data: {'taskId': taskId, 'dueAt': dueAt?.toIso8601String()},
    );
  }

  static AstraResponse taskCompleted(String title) => AstraResponse(
        type: AstraResponseType.taskCompleted,
        headline: 'Task completed',
        lines: [AstraResponseLine(label: '', value: title, highlight: true)],
      );

  static AstraResponse reminderCancelled(String title) => AstraResponse(
        type: AstraResponseType.reminderCancelled,
        headline: 'Reminder cancelled',
        lines: [AstraResponseLine(label: '', value: title, highlight: true)],
      );

  static AstraResponse reminderSnoozed(String title, Duration duration) => AstraResponse(
        type: AstraResponseType.reminderSnoozed,
        headline: 'Reminder snoozed',
        lines: [
          AstraResponseLine(label: '', value: title, highlight: true),
          AstraResponseLine(
            label: 'Snoozed for',
            value: '${duration.inMinutes} minutes',
          ),
        ],
      );

  static AstraResponse info(String headline, {List<AstraResponseLine> lines = const []}) =>
      AstraResponse(type: AstraResponseType.info, headline: headline, lines: lines);

  static AstraResponse error(String message) => AstraResponse(
        type: AstraResponseType.error,
        headline: 'Something went wrong',
        lines: [AstraResponseLine(label: '', value: message)],
      );

  static String _notificationLabel(ScheduleOutcome outcome) => switch (outcome) {
        ScheduleOutcome.scheduled => 'Scheduled',
        ScheduleOutcome.inexactScheduled => 'Scheduled (approximate)',
        ScheduleOutcome.permissionRequired => 'Permission required',
        ScheduleOutcome.pastTime => 'Time in past',
        ScheduleOutcome.failed => 'Failed to schedule',
      };
}
