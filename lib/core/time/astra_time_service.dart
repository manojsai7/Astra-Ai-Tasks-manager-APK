import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'astra_clock.dart';

/// Resolves all temporal expressions against one canonical clock + user timezone.
///
/// Default timezone is [defaultTimezone] (Asia/Kolkata). Later this will come
/// from [UserProfile.timeZone].
class AstraTimeService {
  AstraTimeService({
    AstraClock? clock,
    this._timezone = defaultTimezone,
  }) : _clock = clock ?? SystemAstraClock() {
    _ensureTimezones();
  }

  static const String defaultTimezone = 'Asia/Kolkata';

  final AstraClock _clock;
  String _timezone;

  String get timezone => _timezone;
  AstraClock get clock => _clock;

  /// Returns current canonical time from the underlying clock.
  DateTime now() => _clock.now();

  void setTimezone(String value) {
    _ensureTimezones();
    _timezone = value;
  }

  tz.Location get location => tz.getLocation(_timezone);

  tz.TZDateTime nowTZ() {
    _ensureTimezones();
    final n = _clock.now();
    return tz.TZDateTime(
      location,
      n.year,
      n.month,
      n.day,
      n.hour,
      n.minute,
      n.second,
      n.millisecond,
      n.microsecond,
    );
  }

  tz.TZDateTime toTZ(DateTime dt) {
    _ensureTimezones();
    return tz.TZDateTime(
      location,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }

  tz.TZDateTime buildDateTime(int year, int month, int day, int hour, int minute) {
    return tz.TZDateTime(location, year, month, day, hour, minute);
  }

  /// Rolls [dt] forward by one day if it is already in the past.
  tz.TZDateTime rollForwardIfPast(tz.TZDateTime dt) {
    final now = nowTZ();
    if (dt.isBefore(now)) return dt.add(const Duration(days: 1));
    return dt;
  }

  static bool _tzInitialized = false;

  static void _ensureTimezones() {
    if (_tzInitialized) return;
    try {
      tz_data.initializeTimeZones();
    } catch (_) {
      // Already initialised elsewhere.
    }
    _tzInitialized = true;
  }
}
