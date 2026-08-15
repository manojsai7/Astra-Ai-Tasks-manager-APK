import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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

/// Downloads APK updates directly in-app with progress, size metrics, and native package installer invocation.
class UpdateDownloader {
  /// Downloads the APK and opens it using the native Android package installer (via FileProvider).
  static Future<bool> downloadAndInstall({
    required String url,
    required String fileName,
    void Function(double progress, int downloadedBytes, int totalBytes)? onProgress,
    void Function(UpdateDownloadState state, String? errorMessage)? onStateChanged,
  }) async {
    try {
      if (url.isEmpty) {
        onStateChanged?.call(UpdateDownloadState.failed, 'Empty download URL');
        return false;
      }

      onStateChanged?.call(UpdateDownloadState.downloading, null);

      // 1. Get storage directory: Use app-specific external cache directory or temp directory.
      // On modern Android (10+ / API 29+), app-specific directories require ZERO storage permissions
      // and allow secure FileProvider content sharing directly to the Android package installer.
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
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
      onStateChanged?.call(UpdateDownloadState.downloaded, null);

      // 4. Open APK with native Android package installer
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
      debugPrint('[UpdateDownloader] Error: $e');
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
