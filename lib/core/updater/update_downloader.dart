import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UpdateDownloadState { idle, checking, available, downloading, downloaded, installing, failed, paused }

/// Uses Android DownloadManager so update transfers survive screen-off/backgrounding.
class UpdateDownloader {
  static const String _prefVersionKey = 'updater_downloaded_version';
  static const String _prefPathKey = 'updater_downloaded_path';
  static const String _prefSizeKey = 'updater_downloaded_size';
  static const String _prefStatusKey = 'updater_downloaded_status';
  static const String _prefDownloadIdKey = 'updater_download_id';
  static const MethodChannel _updateChannel = MethodChannel('dev.codehunters.astra/update_bridge');

  static Future<Directory> getPersistentDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final dir = Directory('/storage/emulated/0/Download/ASTRA');
        if (await dir.exists() || (await dir.create(recursive: true)).existsSync()) return dir;
      } catch (_) {}
      try {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) return dir;
      } catch (_) {}
    }
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    } catch (_) {}
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {}
    return getTemporaryDirectory();
  }

  static Future<Map<String, dynamic>?> queryPersistedDownload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_prefDownloadIdKey);
      if (id == null) return null;
      return await _updateChannel.invokeMapMethod<String, dynamic>('queryUpdate', {'downloadId': id});
    } catch (e) {
      debugPrint('[UpdateDownloader] query error: $e');
      return null;
    }
  }

  static Future<File?> getPersistedApk({required String version}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(_prefVersionKey);
      final savedPath = prefs.getString(_prefPathKey);
      if (savedVersion == version && savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        if (await file.exists() && await file.length() > 0) return file;
      }
      final dir = await getPersistentDownloadDirectory();
      final file = File('${dir.path}/ASTRA-v$version.apk');
      if (await file.exists() && await file.length() > 0) return file;
    } catch (_) {}
    return null;
  }

  static Future<bool> installApk(String filePath, {void Function(UpdateDownloadState, String?)? onStateChanged}) async {
    try {
      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) {
        onStateChanged?.call(UpdateDownloadState.failed, 'The update file is missing or incomplete.');
        return false;
      }
      onStateChanged?.call(UpdateDownloadState.installing, null);
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        final id = prefs.getInt(_prefDownloadIdKey);
        if (id != null) {
          try {
            await _updateChannel.invokeMethod('installUpdate', {'downloadId': id});
            return true;
          } catch (e) {
            debugPrint('[UpdateDownloader] Native install failed: $e');
          }
        }
      }
      final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
      if (result.type == ResultType.done) return true;
      onStateChanged?.call(UpdateDownloadState.failed, result.type == ResultType.permissionDenied
          ? 'Android requires permission to install updates from ASTRA.'
          : 'Android could not open the downloaded update.');
      return false;
    } catch (e) {
      debugPrint('[UpdateDownloader] Install error: $e');
      onStateChanged?.call(UpdateDownloadState.failed, 'Could not start the installer.');
      return false;
    }
  }

  static Future<bool> downloadAndInstall({
    required String url,
    required String version,
    void Function(double progress, int downloadedBytes, int totalBytes)? onProgress,
    void Function(UpdateDownloadState state, String? errorMessage)? onStateChanged,
  }) async {
    if (url.isEmpty) {
      onStateChanged?.call(UpdateDownloadState.failed, 'This update is not currently downloadable.');
      return false;
    }
    try {
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        final existingId = prefs.getInt(_prefDownloadIdKey);
        if (existingId != null) {
          final existing = await _updateChannel.invokeMapMethod<String, dynamic>('queryUpdate', {'downloadId': existingId});
          final status = existing?['status'];
          if (status == 'running' || status == 'pending' || status == 'paused') {
            onStateChanged?.call(status == 'paused' ? UpdateDownloadState.paused : UpdateDownloadState.downloading, null);
            return true;
          }
          if (status == 'successful' && await getPersistedApk(version: version) != null) {
            onStateChanged?.call(UpdateDownloadState.downloaded, null);
            return true;
          }
        }
        onStateChanged?.call(UpdateDownloadState.downloading, null);
        final id = await _updateChannel.invokeMethod<int>('enqueueUpdate', {
          'url': url,
          'fileName': 'ASTRA-v$version.apk',
        });
        if (id == null) throw Exception('Android did not return a download ID.');
        await prefs.setInt(_prefDownloadIdKey, id);
        await prefs.setString(_prefVersionKey, version);
        await prefs.setString(_prefStatusKey, 'downloading');
        return true;
      }
      throw UnsupportedError('Direct update download is only supported on Android.');
    } catch (e) {
      debugPrint('[UpdateDownloader] Download error: $e');
      onStateChanged?.call(UpdateDownloadState.failed,
          'The update download was interrupted. Your current ASTRA installation is unchanged. Tap Retry to continue.');
      return false;
    }
  }

  static String friendlyDownloadError(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'The update download was interrupted. Please try again.';
    final text = raw.toLowerCase();
    if (text.contains('connection closed') || text.contains('socketexception') || text.contains('clientexception')) {
      return 'The connection to the update server was interrupted. Your current ASTRA installation is unchanged.';
    }
    if (text.contains('timeout')) return 'The update server took too long to respond. Please try again.';
    if (text.contains('404')) return 'This update package is no longer available.';
    if (text.contains('http 5') || text.contains('server returned')) return 'The update server is temporarily unavailable.';
    return 'ASTRA could not complete the update download. Please try again.';
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) { d /= 1024; i++; }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
