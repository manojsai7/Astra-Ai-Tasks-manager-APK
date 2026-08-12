import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads APK updates directly in-app and invokes the native package installer.
class UpdateDownloader {
  static Future<bool> downloadAndInstall({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (url.isEmpty) return false;

      // 1. Get storage directory (App-specific external storage or temp dir)
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      // 2. Clear old file if exists
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Download APK via HTTP stream
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        debugPrint('[UpdateDownloader] HTTP error ${response.statusCode}');
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      final List<int> bytes = [];
      int downloaded = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(downloaded / contentLength);
        }
      }

      await file.writeAsBytes(bytes);
      debugPrint('[UpdateDownloader] APK downloaded to $filePath (${bytes.length} bytes)');

      // 4. Open APK with native package installer
      final result = await OpenFile.open(filePath);
      debugPrint('[UpdateDownloader] OpenFile result: ${result.type} - ${result.message}');

      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('[UpdateDownloader] Error: $e');
      return false;
    }
  }
}
