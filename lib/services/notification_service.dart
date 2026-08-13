import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;

/// ASTRA Notification Service — flutter_local_notifications v20+ API (named args)
///
/// IST (Asia/Kolkata) is explicitly set so that all reminders fire at the
/// correct local time regardless of device timezone configuration.
///
/// Android permissions (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM / POST_NOTIFICATIONS)
/// are already declared in AndroidManifest.xml.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── Initialization ───────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize timezone database and force IST
    tz.initializeTimeZones();
    try {
      final ist = tz_lib.getLocation('Asia/Kolkata');
      tz_lib.setLocalLocation(ist);
      debugPrint('[NotificationService] Timezone set to Asia/Kolkata (IST +05:30).');
    } catch (e) {
      try {
        tz_lib.setLocalLocation(tz_lib.getLocation('UTC'));
      } catch (_) {}
      debugPrint('[NotificationService] IST not found, falling back to UTC: $e');
    }

    // 2. Platform initialization settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    // v22+ uses named parameters for all arguments in initialize()
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Request Android 13+ notification permission
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      // Request exact alarm permission (Android 12+)
      await androidImpl.requestExactAlarmsPermission();
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialization complete.');
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
  }

  // ─── Task Reminder Scheduling ─────────────────────────────────────────────

  /// Schedules a notification for [scheduledTime] (converted to IST).
  /// Returns `true` if successfully scheduled, `false` if the time is past.
  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _ensureInitialized();

    final ist = tz_lib.getLocation('Asia/Kolkata');
    final scheduledTz = tz_lib.TZDateTime.from(scheduledTime, ist);
    final nowTz = tz_lib.TZDateTime.now(ist);

    if (scheduledTz.isBefore(nowTz)) {
      debugPrint('[NotificationService] Skipped — time is in the past: $scheduledTz');
      return false;
    }

    debugPrint('[NotificationService] Scheduling "$title" at $scheduledTz IST');

    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Reminders',
      channelDescription: 'Critical reminders for your tasks',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // v20+ zonedSchedule uses named parameters
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTz,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return true;
    } catch (e) {
      // Fallback: exact alarm permission denied → use inexact (may be delayed)
      debugPrint('[NotificationService] exactAllowWhileIdle failed, retrying inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTz,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
        return true;
      } catch (e2) {
        debugPrint('[NotificationService] scheduleNotification failed entirely: $e2');
        return false;
      }
    }
  }

  /// Alias kept for backward-compatibility.
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

    final ist = tz_lib.getLocation('Asia/Kolkata');
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
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }
}
