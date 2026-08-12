import 'dart:convert';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import '../../../../core/classification/email_classifier.dart';

/// Data container for extracted email info.
class GmailMessageData {
  final String id;
  final String? threadId;
  final String subject;
  final String sender;
  final DateTime date;
  final String snippet;
  final String bodyText;

  GmailMessageData({
    required this.id,
    this.threadId,
    required this.subject,
    required this.sender,
    required this.date,
    required this.snippet,
    required this.bodyText,
  });
}

/// Service that queries and fetches emails from Gmail API.
class GmailSyncService {
  static const String defaultQuery =
      'exam OR application OR deadline OR registration OR "apply by" OR interview OR assessment OR assignment';

  /// Fetches recent relevant emails from user's inbox.
  Future<List<GmailMessageData>> fetchRelevantEmails(
    auth.AuthClient client, {
    String query = defaultQuery,
    int maxResults = 30,
  }) async {
    final gmailApi = gmail.GmailApi(client);
    final response = await gmailApi.users.messages.list(
      'me',
      q: query,
      maxResults: maxResults,
    );

    final List<GmailMessageData> result = [];
    final messages = response.messages ?? [];

    for (final ref in messages) {
      if (ref.id == null) continue;
      try {
        final message = await gmailApi.users.messages.get('me', ref.id!, format: 'full');
        final data = _parseMessage(message);
        if (data == null) continue;

        // ── Classification Gate ───────────────────────────────────────────
        final classification = EmailClassifier.classify(
          subject: data.subject,
          body: data.bodyText,
          sender: data.sender,
        );

        if (classification.shouldIgnore) {
          // Silently skip promotional / noise emails.
          continue;
        }
        // AUTO_CREATE and CONFIRM emails are both returned to the caller;
        // callers can inspect [GmailMessageData] further if needed.
        result.add(data);
      } catch (_) {
        // Skip individual message fetch errors gracefully.
      }
    }

    return result;
  }

  /// Fetches the newest inbox message directly. This is intentionally separate
  /// from task extraction so questions such as "what is my latest mail?" never
  /// need to fall back to an LLM that cannot see the mailbox.
  Future<GmailMessageData?> fetchLatestInboxEmail(auth.AuthClient client) async {
    final gmailApi = gmail.GmailApi(client);
    final response = await gmailApi.users.messages.list(
      'me',
      q: 'in:inbox',
      maxResults: 1,
    );
    final messages = response.messages ?? [];
    final id = messages.isEmpty ? null : messages.first.id;
    if (id == null) return null;
    final message = await gmailApi.users.messages.get('me', id, format: 'full');
    return _parseMessage(message);
  }

  /// Parses a Gmail [Message] into structured data.
  GmailMessageData? _parseMessage(gmail.Message message) {
    final payload = message.payload;
    if (payload == null) return null;

    String subject = 'No Subject';
    String sender = 'Unknown';
    DateTime date = DateTime.now();

    final headers = payload.headers ?? [];
    for (final h in headers) {
      final name = h.name?.toLowerCase();
      if (name == 'subject') {
        subject = h.value ?? subject;
      } else if (name == 'from') {
        sender = h.value ?? sender;
      } else if (name == 'date') {
        if (h.value != null) {
          try {
            date = DateTime.parse(h.value!);
          } catch (_) {
            // keep default date
          }
        }
      }
    }

    final bodyText = _extractBodyText(payload);
    final snippet = message.snippet ?? '';

    return GmailMessageData(
      id: message.id!,
      threadId: message.threadId,
      subject: subject,
      sender: sender,
      date: date,
      snippet: snippet,
      bodyText: bodyText.isNotEmpty ? bodyText : snippet,
    );
  }

  /// Recursively extracts plain text from MIME payload parts.
  String _extractBodyText(gmail.MessagePart part) {
    if (part.mimeType == 'text/plain' && part.body?.data != null) {
      return _decodeBase64(part.body!.data!);
    }

    if (part.parts != null) {
      final buffer = StringBuffer();
      for (final child in part.parts!) {
        final text = _extractBodyText(child);
        if (text.isNotEmpty) {
          buffer.writeln(text);
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }

    if (part.mimeType == 'text/html' && part.body?.data != null) {
      final html = _decodeBase64(part.body!.data!);
      return _stripHtmlTags(html);
    }

    return '';
  }

  String _decodeBase64(String encoded) {
    try {
      String normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      return utf8.decode(base64.decode(normalized));
    } catch (_) {
      return '';
    }
  }

  String _stripHtmlTags(String html) {
    final regExp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html.replaceAll(regExp, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
