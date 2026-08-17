import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Explicit lifecycle states for the ASTRA updater.
enum UpdateDownloadState {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  failed,
}

/// Downloads APK updates directly to a persistent, user-visible Downloads directory with progress and native installer invocation.
class UpdateDownloader {
  static const String _prefVersionKey = 'updater_downloaded_version';
  static const String _prefPathKey = 'updater_downloaded_path';
  static const String _prefSizeKey = 'updater_downloaded_size';
  static const String _prefStatusKey = 'updater_downloaded_status';

  /// Resolves the user-visible Downloads directory on Android (e.g. `/storage/emulated/0/Download/ASTRA/`) with safe fallbacks.
  static Future<Directory> getPersistentDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final astraDownloads = Directory('/storage/emulated/0/Download/ASTRA');
        if (await astraDownloads.exists() || (await astraDownloads.create(recursive: true)).existsSync()) {
          return astraDownloads;
        }
      } catch (_) {}

      try {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        if (await publicDownloads.exists()) {
          return publicDownloads;
        }
      } catch (_) {}
    }

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) return extDir;
    } catch (_) {}

    try {
      final docDir = await getApplicationDocumentsDirectory();
      return docDir;
    } catch (_) {}

    return getTemporaryDirectory();
  }

  /// Checks if an APK for [version] has already been downloaded and is available in Downloads.
  static Future<File?> getPersistedApk({required String version}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(_prefVersionKey);
      final savedPath = prefs.getString(_prefPathKey);

      if (savedVersion == version && savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        if (await file.exists() && await file.length() > 0) {
          return file;
        }
      }

      // Check standard Downloads location
      final dir = await getPersistentDownloadDirectory();
      final expectedFileName = 'ASTRA-v$version.apk';
      final file = File('${dir.path}/$expectedFileName');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Invokes native Android package installer on the persisted APK via FileProvider.
  static Future<bool> installApk(
    String filePath, {
    void Function(UpdateDownloadState state, String? errorMessage)? onStateChanged,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) {
        onStateChanged?.call(UpdateDownloadState.failed, 'APK file not found or incomplete.');
        return false;
      }

      onStateChanged?.call(UpdateDownloadState.installing, null);
      final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
      debugPrint('[UpdateDownloader] OpenFile result: ${result.type} - ${result.message}');

      if (result.type == ResultType.done) {
        return true;
      } else if (result.type == ResultType.permissionDenied) {
        onStateChanged?.call(
          UpdateDownloadState.failed,
          'Permission required to install unknown apps. Please enable it in Android Settings.',
        );
        return false;
      } else {
        onStateChanged?.call(UpdateDownloadState.failed, result.message);
        return false;
      }
    } catch (e) {
      debugPrint('[UpdateDownloader] Install error: $e');
      onStateChanged?.call(UpdateDownloadState.failed, e.toString());
      return false;
    }
  }

  /// Downloads the APK to a user-visible, persistent location and triggers installation.
  static Future<bool> downloadAndInstall({
    required String url,
    required String version,
    void Function(double progress, int downloadedBytes, int totalBytes)? onProgress,
    void Function(UpdateDownloadState state, String? errorMessage)? onStateChanged,
  }) async {
    try {
      if (url.isEmpty) {
        onStateChanged?.call(UpdateDownloadState.failed, 'Empty download URL');
        return false;
      }

      onStateChanged?.call(UpdateDownloadState.downloading, null);

      // 1. Get persistent user-visible Downloads directory
      final dir = await getPersistentDownloadDirectory();
      final fileName = 'ASTRA-v$version.apk';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      // 2. Clear old file if exists
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      // 3. Download APK via HTTP streaming client
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        debugPrint('[UpdateDownloader] HTTP error ${response.statusCode}');
        onStateChanged?.call(UpdateDownloadState.failed, 'Server returned HTTP ${response.statusCode}');
        client.close();
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          final ratio = (downloaded / contentLength).clamp(0.0, 1.0);
          onProgress(ratio, downloaded, contentLength);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      debugPrint('[UpdateDownloader] APK downloaded to $filePath ($downloaded bytes)');

      // 4. Save metadata to SharedPreferences for persistent reuse across restarts
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefVersionKey, version);
        await prefs.setString(_prefPathKey, filePath);
        await prefs.setInt(_prefSizeKey, downloaded);
        await prefs.setString(_prefStatusKey, 'completed');
      } catch (_) {}

      onStateChanged?.call(UpdateDownloadState.downloaded, null);

      // 5. Trigger installation (APK remains persisted in Downloads)
      return await installApk(filePath, onStateChanged: onStateChanged);
    } catch (e) {
      debugPrint('[UpdateDownloader] Download error: $e');
      onStateChanged?.call(UpdateDownloadState.failed, e.toString());
      return false;
    }
  }

  /// Formats byte count to human-readable string (e.g. "14.2 MB").
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
