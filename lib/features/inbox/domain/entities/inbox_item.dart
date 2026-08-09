/// Type-safe domain representation of an Inbox Item's source origin.
enum InboxSource {
  manual,
  androidShare,
  clipboard;

  /// Returns the matching database string value representation.
  String get value {
    switch (this) {
      case InboxSource.manual:
        return 'MANUAL';
      case InboxSource.androidShare:
        return 'ANDROID_SHARE';
      case InboxSource.clipboard:
        return 'CLIPBOARD';
    }
  }
}

/// Pure domain entity representing an Inbox Item in ASTRA.
///
/// Under strict domain decoupling rules, this class has no dependencies
/// on persistence (Drift) or UI (Flutter) frameworks.
class InboxItem {
  final String id;
  final String rawText;
  final String sourceType;
  final String processingStatus;
  final DateTime receivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InboxItem({
    required this.id,
    required this.rawText,
    required this.sourceType,
    required this.processingStatus,
    required this.receivedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
