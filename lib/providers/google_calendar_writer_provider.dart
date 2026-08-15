import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/scheduler/data/services/google_calendar_writer_service.dart';

/// Exposes the singleton instance of [GoogleCalendarWriterService].
final googleCalendarWriterServiceProvider = Provider<GoogleCalendarWriterService>((ref) {
  return const GoogleCalendarWriterService();
});
