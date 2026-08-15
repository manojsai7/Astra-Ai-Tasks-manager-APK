import '../ml/intent_classifier_client.dart';

class AstraResolvedIntent {
  final String intent;
  final double mlConfidence;
  final String reason;

  const AstraResolvedIntent({
    required this.intent,
    required this.mlConfidence,
    required this.reason,
  });
}

class AstraIntentResolver {
  const AstraIntentResolver();

  AstraResolvedIntent resolve({
    required String text,
    required IntentClassificationResult? ml,
  }) {
    final t = text.trim().toLowerCase();

    if (_isEmailSync(t)) {
      return AstraResolvedIntent(
        intent: 'SYNC_EMAIL',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_email_sync_rule',
      );
    }

    if (_isGeneralChat(t)) {
      return AstraResolvedIntent(
        intent: 'GENERAL_CHAT',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_general_chat_rule',
      );
    }

    if (_isExplicitCalendarCreation(t)) {
      return AstraResolvedIntent(
        intent: 'CREATE_CALENDAR_EVENT',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_calendar_creation_rule',
      );
    }

    if (_isExplicitReminder(t)) {
      return AstraResolvedIntent(
        intent: 'CREATE_REMINDER',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_reminder_rule',
      );
    }

    if (_isTaskListing(t)) {
      return AstraResolvedIntent(
        intent: 'LIST_TASKS',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_task_listing_rule',
      );
    }

    if (_isCalendarQuery(t)) {
      return AstraResolvedIntent(
        intent: 'GET_CALENDAR',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_calendar_query_rule',
      );
    }

    if (_isExplicitTaskCreation(t)) {
      return AstraResolvedIntent(
        intent: 'CREATE_TASK',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_task_creation_rule',
      );
    }

    if (_isCompletion(t)) {
      return AstraResolvedIntent(
        intent: 'COMPLETE_TASK',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_completion_rule',
      );
    }

    if (_isCancellation(t)) {
      return AstraResolvedIntent(
        intent: 'CANCEL_TASK',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_cancellation_rule',
      );
    }

    if (_isTaskUpdate(t)) {
      return AstraResolvedIntent(
        intent: 'UPDATE_TASK',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_task_update_rule',
      );
    }

    if (_isPanchang(t)) {
      return AstraResolvedIntent(
        intent: 'GET_PANCHANG',
        mlConfidence: ml?.confidence ?? 0.0,
        reason: 'deterministic_panchang_rule',
      );
    }

    return AstraResolvedIntent(
      intent: ml?.intent ?? 'GENERAL_CHAT',
      mlConfidence: ml?.confidence ?? 0.0,
      reason: 'ml_model',
    );
  }

  bool _isPanchang(String t) {
    const keywords = {
      'panchang',
      'ekadashi',
      'purnima',
      'amavasya',
      'tithi',
      'nakshatra',
      'rahu kalam',
      'rahukalam',
      'muhurat',
      'muhurtham',
    };

    return keywords.any(t.contains);
  }

  bool _isEmailSync(String t) {
    const emailWords = {
      'email',
      'emails',
      'mail',
      'mails',
      'inbox',
      'gmail',
    };

    const syncWords = {
      'sync',
      'synchronize',
      'refresh',
      'reload',
      'fetch',
      'update',
    };

    return emailWords.any(t.contains) &&
        syncWords.any(t.contains);
  }

  bool _isGeneralChat(String t) {
    const phrases = {
      'hi',
      'hello',
      'hey',
      'what\'s up',
      'whats up',
      'later',
      'bye',
      'good morning',
      'good evening',
      'good night',
    };

    return phrases.contains(t);
  }

  bool _isExplicitCalendarCreation(String t) {
    const phrases = {
      'create a calendar event',
      'create calendar event',
      'put it on the calendar',
      'put it in the calendar',
      'add to my calendar',
      'add it to my calendar',
      'schedule a meeting',
      'schedule an event',
      'schedule a call',
      'schedule an appointment',
    };

    if (phrases.any(t.contains)) {
      return true;
    }

    return t.startsWith('schedule ') &&
        (
          t.contains('today') ||
          t.contains('tomorrow') ||
          t.contains('monday') ||
          t.contains('tuesday') ||
          t.contains('wednesday') ||
          t.contains('thursday') ||
          t.contains('friday') ||
          t.contains('saturday') ||
          t.contains('sunday') ||
          t.contains(' at ')
        );
  }

  bool _isExplicitReminder(String t) {
    const phrases = {
      'remind me',
      'set a reminder',
      'set reminder',
      'notify me',
      'alert me',
    };

    return phrases.any(t.contains);
  }

  bool _isTaskListing(String t) {
    const taskWords = {
      'task',
      'tasks',
      'todo',
      'todos',
      'to-do',
    };

    const listWords = {
      'show',
      'list',
      'display',
      'view',
      'what',
      'which',
    };

    return taskWords.any(t.contains) &&
        listWords.any(t.contains);
  }

  bool _isCalendarQuery(String t) {
    const calendarWords = {
      'calendar',
      'meeting',
      'meetings',
      'event',
      'events',
      'appointment',
      'appointments',
      'schedule',
    };

    const queryWords = {
      'show',
      'list',
      'view',
      'what',
      'when',
      'which',
      'next',
    };

    return calendarWords.any(t.contains) &&
        queryWords.any(t.contains);
  }

  bool _isExplicitTaskCreation(String t) {
    const phrases = {
      'create a task',
      'create task',
      'add task',
      'add this to my tasks',
      'make a task',
      'set task',
    };

    if (phrases.any(t.contains)) return true;

    // Recurrence intent: Phrases like "standup every weekday at 10am" or "water plants daily at 8am"
    if (t.contains('every weekday') ||
        t.contains('every day') ||
        t.contains('every morning') ||
        t.contains('every evening') ||
        t.contains('every week') ||
        t.contains('every month') ||
        t.contains('every monday') ||
        t.contains('every tuesday') ||
        t.contains('every wednesday') ||
        t.contains('every thursday') ||
        t.contains('every friday') ||
        t.contains('every saturday') ||
        t.contains('every sunday') ||
        t.contains('daily at') ||
        t.contains('weekly at') ||
        t.contains('monthly on')) {
      return true;
    }

    return false;
  }

  bool _isCompletion(String t) {
    const phrases = {
      'mark as done',
      'mark it done',
      'mark this done',
      'mark task done',
      'mark completed',
      'already completed',
      'already finished',
      'i completed',
      'i have completed',
      'i finished',
      'i have finished',
      'it\'s done',
      'it is done',
      'done with',
    };

    return phrases.any(t.contains);
  }

  bool _isCancellation(String t) {
    const phrases = {
      'cancel task',
      'cancel my task',
      'remove task',
      'delete task',
      'cancel reminder',
      'cancel my reminder',
    };

    return phrases.any(t.contains);
  }

  bool _isTaskUpdate(String t) {
    const phrases = {
      'update task',
      'change task',
      'edit task',
      'reschedule task',
    };

    return phrases.any(t.contains);
  }
}
