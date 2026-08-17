import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Represents a document selected by the user via the system document picker.
class AstraPickedDocument {
  final String name;
  final Uint8List bytes;
  final String? path;

  const AstraPickedDocument({
    required this.name,
    required this.bytes,
    this.path,
  });
}

/// Abstract contract for platform document picker/saver.
/// Isolates platform channels so backup/restore logic is 100% unit-testable.
abstract class IAstraBackupStorageService {
  Future<String?> saveBackupDocument({
    required String fileName,
    required Uint8List bytes,
  });

  Future<AstraPickedDocument?> pickBackupDocument();
}

/// Production implementation of [IAstraBackupStorageService] using Storage Access Framework (SAF).
class AstraBackupStorageService implements IAstraBackupStorageService {
  const AstraBackupStorageService();

  @override
  Future<String?> saveBackupDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      // 1. Attempt system document save dialog (SAF ACTION_CREATE_DOCUMENT)
      final savedUri = await FilePickerPlatform.instance.saveFile(
        dialogTitle: 'Choose where to save your ASTRA backup',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/octet-stream',
      );

      if (savedUri != null) {
        final uriString = savedUri.toString();
        // If it's a file scheme, ensure bytes are written
        if (savedUri.isScheme('file') || !uriString.startsWith('content:')) {
          try {
            final filePath = savedUri.toFilePath();
            final file = File(filePath);
            if (!await file.exists() || (await file.length()) == 0) {
              await file.writeAsBytes(bytes);
            }
            return filePath;
          } catch (_) {}
        }
        return uriString;
      }

      // Fallback if user cancels or platform saveFile returns null:
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {}
      targetDir ??= await getApplicationDocumentsDirectory();

      final fallbackFile = File('${targetDir.path}/$fileName');
      await fallbackFile.writeAsBytes(bytes);
      return fallbackFile.path;
    } catch (e) {
      debugPrint('[AstraBackupStorageService] saveBackupDocument error: $e');
      // Emergency fallback write
      final dir = await getApplicationDocumentsDirectory();
      final emergencyFile = File('${dir.path}/$fileName');
      await emergencyFile.writeAsBytes(bytes);
      return emergencyFile.path;
    }
  }

  @override
  Future<AstraPickedDocument?> pickBackupDocument() async {
    try {
      // Open Android SAF ACTION_OPEN_DOCUMENT file picker
      final files = await FilePickerPlatform.instance.pickFiles(
        dialogTitle: 'Select an .astra.db backup from Downloads, Drive, or Files',
      );

      if (files.isEmpty) {
        return null;
      }

      final file = files.first;
      Uint8List fileBytes;
      try {
        fileBytes = await file.readAsBytes();
      } catch (_) {
        if (file.path != null && file.path!.isNotEmpty) {
          fileBytes = await File(file.path!).readAsBytes();
        } else {
          throw Exception('Unable to read content from the selected document.');
        }
      }

      if (fileBytes.isEmpty) {
        throw Exception('Unable to read content from the selected document.');
      }

      return AstraPickedDocument(
        name: file.name,
        bytes: fileBytes,
        path: file.path,
      );
    } catch (e) {
      debugPrint('[AstraBackupStorageService] pickBackupDocument error: $e');
      rethrow;
    }
  }
}
