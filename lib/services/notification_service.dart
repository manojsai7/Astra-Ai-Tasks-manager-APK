import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Request permissions for Android 13+
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Only schedule if scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      channelDescription: 'Critical reminders for your tasks',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Exact alarm permission may be denied on some Android 12+ devices.
      // The notification will be skipped gracefully.
      debugPrint('[NotificationService] scheduleNotification failed: $e');
    }
  }

  static Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
  }

  /// Dedicated Panchang reminder — uses its own notification channel so users
  /// can manage them separately in Android Settings.
  static Future<void> schedulePanchangReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'panchang_channel',
      'Panchang Reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      channelDescription: 'Reminders for Ekadashi, Purnima, Amavasya and other events',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[NotificationService] schedulePanchangReminder failed: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
