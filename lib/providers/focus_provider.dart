import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusStats {
  final int totalSessions;
  final int totalMinutes;
  const FocusStats({this.totalSessions = 0, this.totalMinutes = 0});
}

class FocusStatsNotifier extends StateNotifier<FocusStats> {
  FocusStatsNotifier() : super(const FocusStats());

  void addSession(int minutes) {
    state = FocusStats(
      totalSessions: state.totalSessions + 1,
      totalMinutes: state.totalMinutes + minutes,
    );
  }
}

final focusStatsProvider = StateNotifierProvider<FocusStatsNotifier, FocusStats>((ref) {
  return FocusStatsNotifier();
});
