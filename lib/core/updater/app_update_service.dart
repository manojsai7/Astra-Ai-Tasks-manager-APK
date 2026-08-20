import 'package:flutter/material.dart';
import 'app_updater.dart';
import 'update_sheet.dart';

/// Application-level update service that decouples update checks
/// from individual screen rendering (e.g. HomeScreen post-frame callbacks).
class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._();
  AppUpdateService._();

  UpdateInfo? _latestInfo;
  bool _isChecking = false;

  UpdateInfo? get latestInfo => _latestInfo;
  bool get isChecking => _isChecking;

  /// Checks for available updates silently in the background.
  /// If an update is available and [context] is provided and mounted, presents the update sheet.
  Future<UpdateInfo?> checkForUpdates({BuildContext? context, bool autoShowSheet = false}) async {
    if (_isChecking) return _latestInfo;
    _isChecking = true;

    try {
      final info = await AppUpdater.check();
      _latestInfo = info;
      _isChecking = false;

      if (info != null && info.isAvailable && autoShowSheet && context != null && context.mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => UpdateSheet(info: info),
        );
      }
      return info;
    } catch (e) {
      debugPrint('[AppUpdateService] Check failed: $e');
      _isChecking = false;
      return null;
    }
  }
}
