import 'package:tithi_engine/tithi_engine.dart';
import 'package:tithi_engine/data/india.dart';

/// Represents a single Panchang event (Ekadashi, Purnima, Amavasya, etc.)
class PanchangEvent {
  final String eventName;
  final String displayName;
  final DateTime eventDate;
  final String paksha;
  final String lunarMonth;
  final String description;
  final int calendarYear;
  final String emoji;

  const PanchangEvent({
    required this.eventName,
    required this.displayName,
    required this.eventDate,
    required this.paksha,
    required this.lunarMonth,
    required this.description,
    required this.calendarYear,
    required this.emoji,
  });

  bool get isEkadashi => eventName == 'Ekadashi';
  bool get isPurnima => eventName == 'Purnima';
  bool get isAmavasya => eventName == 'Amavasya';
  bool get isShivaratri => eventName == 'Shivaratri';

  /// Number of days from today to the event.
  int get daysFromNow {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final eventDateOnly =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    return eventDateOnly.difference(todayDate).inDays;
  }
}

/// Service to compute Panchang events using the tithi_engine package.
/// Uses Hyderabad as the default city for Telugu-speaking users.
class PanchangService {
  static final _panchang = Panchang([registerIndia]);

  // Default city: Hyderabad (Telangana)
  static final _city = City.of('Hyderabad');

  /// Computes all Ekadashi, Purnima, Amavasya, Shivaratri events
  /// for the next [months] months.
  static List<PanchangEvent> getUpcomingEvents({int months = 3}) {
    final now = DateTime.now();
    final events = <PanchangEvent>[];

    for (int i = 0; i < months; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);
      final year = targetDate.year;
      final month = targetDate.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime.utc(year, month, day);
        try {
          final info = _panchang.tithiOnDate(date, _city);
          final tithiName = info.tithiName;
          final paksha = info.paksha == Paksha.shukla ? 'Shukla' : 'Krishna';
          final lunarMonth = info.month.displayName;

          String? eventName;
          String? emoji;
          String? description;

          if (tithiName == 'Ekadashi') {
            eventName = 'Ekadashi';
            emoji = '🕉️';
            description =
                '$paksha Ekadashi of $lunarMonth – Fast, worship Vishnu, avoid grains.';
          } else if (tithiName == 'Purnima') {
            eventName = 'Purnima';
            emoji = '🌕';
            description =
                'Full Moon day of $lunarMonth – Satyanarayan pooja, charity, temple visit.';
          } else if (tithiName == 'Amavasya') {
            eventName = 'Amavasya';
            emoji = '🌑';
            description =
                'New Moon – Pitru tarpan, ancestor rituals, donations.';
          } else if (tithiName == 'Chaturdashi' && paksha == 'Krishna') {
            // Krishna Chaturdashi = Masa Shivaratri (monthly)
            eventName = 'Shivaratri';
            emoji = '🔱';
            description =
                'Masa Shivaratri of $lunarMonth – Shiva puja, fasting, night vigil.';
          }

          if (eventName != null) {
            events.add(PanchangEvent(
              eventName: eventName,
              displayName: '$paksha $eventName',
              eventDate: DateTime(year, month, day),
              paksha: paksha,
              lunarMonth: lunarMonth,
              description: description ?? '',
              calendarYear: year,
              emoji: emoji!,
            ));
          }
        } catch (_) {
          // Skip dates that fail calculation
        }
      }
    }

    // Filter to today/future events and sort by date
    return events
        .where((e) => !e.eventDate
            .isBefore(DateTime.now().subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  /// Get today's Tithi info string for the home screen widget.
  static String getTodayTithiDisplay() {
    try {
      final info = _panchang.tithiOnDate(DateTime.now().toUtc(), _city);
      final paksha = info.paksha == Paksha.shukla ? 'Shukla' : 'Krishna';
      return '${info.month.displayName} $paksha ${info.tithiName}';
    } catch (_) {
      return 'Panchang unavailable';
    }
  }

  /// Get today's full Panchang info.
  static Map<String, String> getTodayPanchang() {
    try {
      final today = DateTime.now().toUtc();
      final info = _panchang.tithiOnDate(today, _city);
      final paksha = info.paksha == Paksha.shukla ? 'Shukla' : 'Krishna';
      final sunriseUtc = _panchang.sunrise(today, _city);
      final sunriseIst =
          sunriseUtc.add(const Duration(hours: 5, minutes: 30));
      return {
        'tithi': '${info.tithiName} ($paksha)',
        'month': info.month.displayName,
        'sunrise':
            '${sunriseIst.hour.toString().padLeft(2, '0')}:${sunriseIst.minute.toString().padLeft(2, '0')} IST',
      };
    } catch (_) {
      return {'tithi': 'N/A', 'month': 'N/A', 'sunrise': 'N/A'};
    }
  }
}
