import 'dart:convert';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import '../../../../core/classification/email_classifier.dart';

/// Data container for extracted email info with rich sender, MIME, and attachment metadata.
class GmailMessageData {
  final String id;
  final String? threadId;
  final String subject;
  final String sender;
  final String senderName;
  final String senderEmail;
  final DateTime date;
  DateTime get receivedAt => date;
  final String snippet;
  final String bodyText;
  final List<String> attachments;

  GmailMessageData({
    required this.id,
    this.threadId,
    required this.subject,
    required this.sender,
    String? senderName,
    String? senderEmail,
    required this.date,
    required this.snippet,
    required this.bodyText,
    this.attachments = const [],
  })  : senderName = senderName ?? GmailSyncService.extractSenderName(sender),
        senderEmail = senderEmail ?? GmailSyncService.extractSenderEmail(sender);
}

/// Service that queries and fetches emails from Gmail API with robust MIME extraction.
class GmailSyncService {
  static const String defaultQuery =
      'exam OR application OR deadline OR registration OR "apply by" OR interview OR assessment OR assignment';

  /// Extracts display name from standard `From: "Name" <email>` headers.
  static String extractSenderName(String sender) {
    final trimmed = sender.trim();
    if (trimmed.isEmpty) return 'Unknown';

    // Matches: "Display Name" <email> or Display Name <email>
    final match = RegExp(r'^(?:"?([^"<]+)"?\s*)?<([^>]+)>$').firstMatch(trimmed);
    if (match != null) {
      final name = match.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
      final email = match.group(2)?.trim();
      if (email != null && email.isNotEmpty) return email;
    }
    return trimmed;
  }

  /// Extracts email address from `From:` header.
  static String extractSenderEmail(String sender) {
    final match = RegExp(r'<([^>]+)>').firstMatch(sender);
    if (match != null) {
      return match.group(1)?.trim() ?? sender;
    }
    return sender.trim();
  }

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
        result.add(data);
      } catch (_) {
        // Skip individual message fetch errors gracefully.
      }
    }

    return result;
  }

  /// Fetches the newest inbox message directly.
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

    final attachments = <String>[];
    final bodyText = extractBodyText(payload, attachments: attachments);
    final snippet = message.snippet ?? '';

    return GmailMessageData(
      id: message.id!,
      threadId: message.threadId,
      subject: subject,
      sender: sender,
      date: date,
      snippet: snippet,
      bodyText: bodyText.isNotEmpty ? bodyText : snippet,
      attachments: attachments,
    );
  }

  /// Recursively extracts clean plain text and attachment metadata from MIME payload parts.
  static String extractBodyText(gmail.MessagePart part, {List<String>? attachments}) {
    if (part.filename != null && part.filename!.trim().isNotEmpty) {
      attachments?.add(part.filename!.trim());
    }

    final mime = part.mimeType?.toLowerCase() ?? '';

    // 1. Direct text/plain
    if (mime == 'text/plain' && part.body?.data != null) {
      final decoded = decodeBase64(part.body!.data!);
      if (decoded.isNotEmpty) return decoded.trim();
    }

    // 2. Direct text/html
    if (mime == 'text/html' && part.body?.data != null) {
      final html = decodeBase64(part.body!.data!);
      return stripHtmlTags(html);
    }

    // 3. Multipart / nested structures
    if (part.parts != null && part.parts!.isNotEmpty) {
      // For multipart/alternative, prefer plain text part over html part
      if (mime == 'multipart/alternative') {
        String? plainCandidate;
        String? htmlCandidate;

        for (final child in part.parts!) {
          final childMime = child.mimeType?.toLowerCase() ?? '';
          if (childMime == 'text/plain') {
            final t = extractBodyText(child, attachments: attachments);
            if (t.isNotEmpty) plainCandidate = t;
          } else if (childMime == 'text/html') {
            final t = extractBodyText(child, attachments: attachments);
            if (t.isNotEmpty) htmlCandidate = t;
          } else {
            final t = extractBodyText(child, attachments: attachments);
            if (t.isNotEmpty && plainCandidate == null) plainCandidate = t;
          }
        }

        if (plainCandidate != null && plainCandidate.isNotEmpty) return plainCandidate;
        if (htmlCandidate != null && htmlCandidate.isNotEmpty) return htmlCandidate;
      }

      // For multipart/mixed, multipart/related, or general nested parts: concatenate all
      final buffer = StringBuffer();
      for (final child in part.parts!) {
        final text = extractBodyText(child, attachments: attachments);
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(text);
        }
      }
      if (buffer.isNotEmpty) return buffer.toString().trim();
    }

    return '';
  }

  /// URL-safe and standard base64 decoding.
  static String decodeBase64(String encoded) {
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

  /// Converts HTML to clean, readable plain text while preserving paragraph structure,
  /// dates, times, deadlines, URLs, and decoding standard HTML entities.
  static String stripHtmlTags(String html) {
    if (html.isEmpty) return '';

    String cleaned = html;

    // Replace block-level & line-break tags with newlines
    cleaned = cleaned.replaceAll(RegExp(r'<(?:br|p|div|tr|li|h[1-6])\b[^>]*>', caseSensitive: false), '\n');
    cleaned = cleaned.replaceAll(RegExp(r'</(?:p|div|tr|li|h[1-6])>', caseSensitive: false), '\n');

    // Strip script and style blocks entirely
    cleaned = cleaned.replaceAll(RegExp(r'<(?:script|style)\b[^>]*>[\s\S]*?<\/(?:script|style)>', caseSensitive: false), ' ');

    // Strip remaining HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // Decode HTML entities
    cleaned = cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&ndash;', '-')
        .replaceAll('&mdash;', '--');

    // Normalize spacing per line while preserving meaningful line breaks
    final lines = cleaned.split('\n').map((l) => l.replaceAll(RegExp(r'[ \t\r\f]+'), ' ').trim()).where((l) => l.isNotEmpty);
    return lines.join('\n');
  }
}

