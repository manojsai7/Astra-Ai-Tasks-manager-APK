import 'package:flutter/services.dart';

/// Service responsible for managing foreground clipboard intake.
///
/// Under Phase 1C:
/// - Reads clipboard only when requested (not on a polling loop or background service).
/// - Dedupes prompts by storing the last processed clipboard value in memory.
class ClipboardIntakeService {
  final Future<String?> Function() _clipboardGetter;
  String? _lastProcessedValue;

  ClipboardIntakeService({Future<String?> Function()? clipboardGetter})
    : _clipboardGetter =
          clipboardGetter ??
          (() async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            return data?.text;
          });

  /// Retrieves the text content currently on the clipboard.
  /// Returns `null` if clipboard is empty or an error occurs.
  Future<String?> getClipboardText() async {
    try {
      return await _clipboardGetter();
    } catch (_) {
      // Platform channels can throw if clipboard is not accessible
      return null;
    }
  }

  /// Determines if a prompt should be shown for the given clipboard text.
  ///
  /// A prompt is shown only if:
  /// - The text is not null.
  /// - The text (trimmed) is not empty.
  /// - The text is different from the last processed (ingested/ignored/empty) clipboard value.
  bool shouldPrompt(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return text != _lastProcessedValue;
  }

  /// Marks a text as processed so the app won't immediately prompt again.
  void markProcessed(String? text) {
    _lastProcessedValue = text;
  }

  /// Resets the tracker state. Useful for unit tests.
  void clear() {
    _lastProcessedValue = null;
  }

  /// Retrieves the last processed value for validation/testing.
  String? get lastProcessedValue => _lastProcessedValue;
}
