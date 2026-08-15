import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;

import '../core/time/astra_time_service.dart';

/// Result of a notification scheduling attempt — honest, structured status.
enum NotificationScheduleResult {
  exact,
  inexact,
  permissionRequired,
  pastTime,
  failed,
}

typedef NotificationActionCallback = Future<void> Function(String actionId, String? payload);

/// ASTRA Notification Service — schedules task reminders with action buttons.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static NotificationActionCallback? _actionCallback;

  static const String actionDone = 'done';
  static const String actionSnooze10m = 'snooze_10m';
  static const String actionOpenTask = 'open_task';

  static String _timezone = AstraTimeService.defaultTimezone;

  static void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  static void setTimezone(String timezone) {
    _timezone = timezone;
  }

  // ─── Initialization ───────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final loc = tz_lib.getLocation(_timezone);
      tz_lib.setLocalLocation(loc);
      debugPrint('[NotificationService] Timezone set to $_timezone.');
    } catch (e) {
      try {
        tz_lib.setLocalLocation(tz_lib.getLocation('UTC'));
      } catch (_) {}
      debugPrint('[NotificationService] Timezone fallback to UTC: $e');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialization complete.');
  }

  static Future<void> _onNotificationResponse(NotificationResponse response) async {
    debugPrint('[NotificationService] Response: action=${response.actionId}, payload=${response.payload}');

    if (response.actionId != null && _actionCallback != null) {
      await _actionCallback!(response.actionId!, response.payload);
      return;
    }

    // Tap without action → open task (logged for now).
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
  }

  // ─── Task Reminder Scheduling ─────────────────────────────────────────────

  /// Schedules a rich reminder notification with DONE / SNOOZE actions.
  static Future<NotificationScheduleResult> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _ensureInitialized();

    final ist = tz_lib.getLocation(_timezone);
    final scheduledTz = tz_lib.TZDateTime.from(scheduledTime, ist);
    final nowTz = tz_lib.TZDateTime.now(ist);

    if (scheduledTz.isBefore(nowTz)) {
      debugPrint('[NotificationService] Skipped — time is in the past: $scheduledTz');
      return NotificationScheduleResult.pastTime;
    }

    debugPrint('[NotificationService] Scheduling "$title" at $scheduledTz ($_timezone)');

    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Reminders',
      channelDescription: 'Critical reminders for your tasks and deadlines',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionDone,
          'DONE',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze10m,
          'SNOOZE 10m',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'task_reminder',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    bool? exactAllowed;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        exactAllowed = await androidPlugin.canScheduleExactNotifications();
      }
    } catch (_) {}

    debugPrint(
      '[NotificationService DIAGNOSTIC] id=$id title="$title" '
      'requestedTime=$scheduledTime scheduledTz=$scheduledTz nowTz=$nowTz '
      'timezone=$_timezone exactAlarmPermission=$exactAllowed',
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '⏰ $title',
        body: body,
        scheduledDate: scheduledTz,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('[NotificationService DIAGNOSTIC] result=EXACT (exactAllowWhileIdle succeeded)');
      return NotificationScheduleResult.exact;
    } catch (e) {
      debugPrint('[NotificationService DIAGNOSTIC] exactAllowWhileIdle failed: $e. Falling back to inexactAllowWhileIdle.');
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: '⏰ $title',
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
        debugPrint('[NotificationService DIAGNOSTIC] result=INEXACT (inexactAllowWhileIdle succeeded — may be delayed by Android Doze/battery optimization)');
        return NotificationScheduleResult.inexact;
      } catch (e2) {
        final err = e2.toString().toLowerCase();
        if (err.contains('exact') || err.contains('alarm') || err.contains('permission')) {
          debugPrint('[NotificationService DIAGNOSTIC] result=PERMISSION_REQUIRED ($e2)');
          return NotificationScheduleResult.permissionRequired;
        }
        debugPrint('[NotificationService DIAGNOSTIC] result=FAILED ($e2)');
        return NotificationScheduleResult.failed;
      }
    }
  }

  /// Backward-compatible wrapper returning bool.
  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final result = await scheduleReminderNotification(
      id: id,
      title: title.replaceFirst('⏰ Reminder: ', ''),
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
    return result == NotificationScheduleResult.exact ||
        result == NotificationScheduleResult.inexact;
  }

  static Future<bool> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) =>
      scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: id.toString(),
      );

  // ─── Panchang Reminders ───────────────────────────────────────────────────

  static Future<bool> schedulePanchangReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _ensureInitialized();

    final ist = tz_lib.getLocation(_timezone);
    final scheduledTz = tz_lib.TZDateTime.from(scheduledTime, ist);
    if (scheduledTz.isBefore(tz_lib.TZDateTime.now(ist))) return false;

    const androidDetails = AndroidNotificationDetails(
      'panchang_channel',
      'Panchang Reminders',
      channelDescription: 'Reminders for Ekadashi, Purnima, Amavasya and other events',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTz,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] schedulePanchangReminder failed: $e');
      return false;
    }
  }

  // ─── Cancellation ─────────────────────────────────────────────────────────

  static Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[NotificationService] cancelNotification failed or running in test: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] cancelAllNotifications failed: $e');
    }
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('[NotificationService] initialize failed or running in test: $e');
      }
    }
  }
}
