import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;
import 'package:url_launcher/url_launcher.dart';

import '../core/database/database.dart';
import '../core/time/astra_time_service.dart';
import 'reminder_service.dart';

/// Result of a notification scheduling attempt — honest, structured status.
enum NotificationScheduleResult {
  exact,
  inexact,
  permissionRequired,
  pastTime,
  failed,
}

/// Reminder permission and exact alarm readiness state.
enum ReminderReadinessState {
  ready,
  notificationPermissionRequired,
  exactAlarmPermissionRequired,
  restricted,
  unknown,
}

typedef NotificationActionCallback = Future<void> Function(String actionId, String? payload);

/// Background isolate notification response entry-point.
@pragma('vm:entry-point')
void astraNotificationBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    tz.initializeTimeZones();
  } catch (_) {}
  await NotificationService.handleNotificationActionResponse(response, isBackground: true);
}

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

  /// Checks the current platform notification and exact alarm readiness state.
  /// Strictly returns [ReminderReadinessState.unknown] on exception or missing plugin implementation.
  static Future<ReminderReadinessState> checkReminderReadiness() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notifAllowed = await androidImpl.areNotificationsEnabled();
        if (notifAllowed == null) return ReminderReadinessState.unknown;
        if (!notifAllowed) {
          return ReminderReadinessState.notificationPermissionRequired;
        }

        final exactAllowed = await androidImpl.canScheduleExactNotifications();
        if (exactAllowed == null) return ReminderReadinessState.unknown;
        if (!exactAllowed) {
          return ReminderReadinessState.exactAlarmPermissionRequired;
        }

        return ReminderReadinessState.ready;
      }
      return ReminderReadinessState.unknown;
    } catch (e) {
      debugPrint('[NotificationService] checkReminderReadiness error: $e');
      return ReminderReadinessState.unknown;
    }
  }

  /// Requests the OS POST_NOTIFICATIONS permission.
  /// If the system dialog cannot be shown (already denied), falls back to
  /// opening the app's notification settings so the user can enable manually.
  static Future<bool> requestNotificationPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // areNotificationsEnabled() == true means already granted — skip dialog.
        final alreadyGranted = await androidImpl.areNotificationsEnabled() ?? false;
        if (alreadyGranted) return true;

        final granted = await androidImpl.requestNotificationsPermission();
        if (granted == true) return true;

        // Dialog may have been blocked (user tapped "Don't ask again").
        // Open app notification settings as a fallback.
        await _openAppNotificationSettings();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] requestNotificationPermission error: $e');
      await _openAppNotificationSettings();
      return false;
    }
  }

  /// Opens the system Alarms & Reminders settings page for this app.
  /// On Android 12+ (API 31+) this is ACTION_REQUEST_SCHEDULE_EXACT_ALARM.
  /// Falls back to app details settings on older versions.
  static Future<bool> requestExactAlarmPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Already granted — nothing to do.
        final alreadyGranted = await androidImpl.canScheduleExactNotifications() ?? false;
        if (alreadyGranted) return true;
      }

      // Primary path: open ACTION_REQUEST_SCHEDULE_EXACT_ALARM (Android 12+).
      // This is the only way to grant SCHEDULE_EXACT_ALARM — system dialog.
      final opened = await _openExactAlarmSettings();
      if (!opened) {
        // Fallback: open app details settings.
        await _openAppNotificationSettings();
      }
      // Return false — caller must re-check via checkReminderReadiness() on resume.
      return false;
    } catch (e) {
      debugPrint('[NotificationService] requestExactAlarmPermission error: $e');
      await _openExactAlarmSettings();
      return false;
    }
  }

  /// Opens Android → Settings → Apps → [ASTRA] → Alarms & Reminders.
  /// Returns true if the intent launched successfully.
  static Future<bool> _openExactAlarmSettings() async {
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      return false;
    }

    const packageId = 'dev.codehunters.astra';

    // Android 12+ (API 31+): ACTION_REQUEST_SCHEDULE_EXACT_ALARM
    // The intent URI format that url_launcher handles on Android:
    //   intent:<data>#Intent;action=<action>;end
    // For package-targeted Settings actions, the data is the package URI.
    final List<Uri> candidates = [
      // Standard Settings action URI (works on most launchers)
      Uri.parse(
        'intent://package/$packageId#Intent;'
        'action=android.settings.REQUEST_SCHEDULE_EXACT_ALARM;end',
      ),
      // Direct app detail fallback — user can navigate to Alarms & Reminders from there
      Uri.parse(
        'intent://package/$packageId#Intent;'
        'action=android.settings.APPLICATION_DETAILS_SETTINGS;end',
      ),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
    return false;
  }

  /// Opens the app's system notification settings page.
  static Future<void> _openAppNotificationSettings() async {
    if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
      return;
    }

    const packageId = 'dev.codehunters.astra';
    final List<Uri> candidates = [
      // Notification settings for this specific app
      Uri.parse(
        'intent://package/$packageId#Intent;'
        'action=android.settings.APP_NOTIFICATION_SETTINGS;end',
      ),
      // App detail settings (has Notifications section)
      Uri.parse(
        'intent://package/$packageId#Intent;'
        'action=android.settings.APPLICATION_DETAILS_SETTINGS;end',
      ),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
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
      onDidReceiveBackgroundNotificationResponse: astraNotificationBackgroundHandler,
    );

    // NOTE: Permission requests (POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM) are
    // intentionally NOT issued here. They are driven by the first-run onboarding
    // flow (OnboardingScreen) so the user receives proper rationale before any
    // OS dialog appears. Call requestNotificationPermission() and
    // requestExactAlarmPermission() explicitly from the onboarding steps.

    _initialized = true;
    debugPrint('[NotificationService] Initialization complete.');
  }

  static Future<void> _onNotificationResponse(NotificationResponse response) async {
    await handleNotificationActionResponse(response, isBackground: false);
  }

  /// Authoritative handling of notification action responses with structured diagnostics.
  static Future<void> handleNotificationActionResponse(
    NotificationResponse response, {
    bool isBackground = false,
  }) async {
    final now = DateTime.now();
    final actionId = response.actionId ?? NotificationService.actionOpenTask;
    final payload = response.payload;

    String? taskId;
    String? reminderId;

    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        taskId = data['taskId'] as String?;
        reminderId = data['reminderId'] as String?;
        final scheduledAtStr = data['scheduledAt'] as String? ?? data['occurrence'] as String? ?? '';
        int driftMs = 0;
        if (scheduledAtStr.isNotEmpty) {
          final sched = DateTime.tryParse(scheduledAtStr);
          if (sched != null) {
            driftMs = now.difference(sched).inMilliseconds;
          }
        }
        debugPrint(
          '[ASTRA NOTIFICATION FIRED]\n'
          'taskId=$taskId\n'
          'reminderId=$reminderId\n'
          'scheduledAt=$scheduledAtStr\n'
          'actualAt=$now\n'
          'delayMs=$driftMs',
        );
        debugPrint(
          '[ASTRA ALARM FIRED]\n'
          'taskId=$taskId\n'
          'scheduledAt=$scheduledAtStr\n'
          'firedAt=$now\n'
          'driftMs=$driftMs',
        );
      } catch (_) {}
    }

    debugPrint(
      '[ASTRA ACTION]\n'
      'action=$actionId\n'
      'taskId=$taskId\n'
      'reminderId=$reminderId\n'
      'payloadValid=${payload != null && payload.isNotEmpty}\n'
      'isBackground=$isBackground',
    );

    if (payload == null || payload.isEmpty) {
      debugPrint('[ASTRA NOTIF ACTION COMPLETE]\nsuccess=false\nnewScheduledAt=null');
      return;
    }

    bool success = false;
    DateTime? newScheduledAt;

    try {
      if (!isBackground && _actionCallback != null) {
        await _actionCallback!(actionId, payload);
      } else {
        final db = constructDb();
        try {
          final reminderService = ReminderService(db);
          await reminderService.handleNotificationAction(actionId, payload);
        } finally {
          await db.close();
        }
      }

      if (actionId == NotificationService.actionSnooze10m) {
        newScheduledAt = now.add(const Duration(minutes: 10));
      }
      success = true;
    } catch (e) {
      debugPrint('[NotificationService] Action execution error: $e');
      success = false;
    }

    debugPrint(
      '[ASTRA NOTIF ACTION COMPLETE]\n'
      'success=$success\n'
      'newScheduledAt=$newScheduledAt',
    );
  }

  // ─── Task Reminder Scheduling ─────────────────────────────────────────────

  /// Schedules a rich reminder notification with DONE / SNOOZE actions.
  static Future<NotificationScheduleResult> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? taskId,
    DateTime? occurrence,
    String? offsetStr,
    String? strategyStr,
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

    final bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: 'ASTRA',
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Reminders',
      channelDescription: 'Critical reminders for your tasks and deadlines',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      styleInformation: bigTextStyle,
      category: AndroidNotificationCategory.reminder,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionDone,
          'DONE',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze10m,
          '+10 MIN',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'task_reminder',
    );

    final notificationDetails = NotificationDetails(
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

    final tId = taskId ?? (payload != null ? _extractTaskId(payload) : '$id');
    final occ = occurrence ?? scheduledTime;
    final off = offsetStr ?? '0m';

    debugPrint(
      '[ASTRA NOTIFICATION TRACE]\n'
      'taskId=$tId\n'
      'requestedAt=$nowTz\n'
      'scheduledAt=$scheduledTz\n'
      'nowAtSchedule=$nowTz\n'
      'timezone=$_timezone\n'
      'exactAlarmPermission=$exactAllowed\n'
      'scheduleMode=exactAllowWhileIdle\n'
      'notificationId=$id',
    );

    debugPrint(
      '[ASTRA ALARM SCHEDULED]\n'
      'task=$tId\n'
      'occurrence=$occ\n'
      'offset=$off\n'
      'requestedAt=$nowTz\n'
      'scheduledAt=$scheduledTz\n'
      'exactPermission=$exactAllowed\n'
      'alarmMode=exactAllowWhileIdle',
    );

    debugPrint(
      '[NotificationService DIAGNOSTIC] id=$id title="$title" '
      'requestedTime=$scheduledTime scheduledTz=$scheduledTz nowTz=$nowTz '
      'timezone=$_timezone exactAlarmPermission=$exactAllowed',
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
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
          title: title,
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

  static String _extractTaskId(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['taskId'] as String? ?? 'unknown';
    } catch (_) {
      return 'unknown';
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
