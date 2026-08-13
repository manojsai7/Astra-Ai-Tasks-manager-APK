import 'astra_command.dart';

/// Result of normalizing raw user input.
class NormalizedMessage {
  final String raw;
  final String normalized;
  final String payload;
  final AstraCommandMode mode;

  const NormalizedMessage({
    required this.raw,
    required this.normalized,
    required this.payload,
    required this.mode,
  });
}

/// Cleans and canonicalizes chat input before intent classification.
class MessageNormalizer {
  static final _prefixRe = RegExp(
    r'^(?:/(task|calendar|mail|panchang)|@(task|calendar|mail|panchang))\s+',
    caseSensitive: false,
  );

  static final _timezoneNoise = RegExp(
    r'\b(?:indian\s+standard\s+time|ist|asia/kolkata|timezone)\b',
    caseSensitive: false,
  );

  static NormalizedMessage normalize(String raw) {
    var text = raw.trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    final normalized = text.toLowerCase().replaceAll(RegExp(r'[?.!]+$'), '').trim();

    AstraCommandMode mode = AstraCommandMode.none;
    var payload = normalized;

    final prefixMatch = _prefixRe.firstMatch(normalized);
    if (prefixMatch != null) {
      final key = (prefixMatch.group(1) ?? prefixMatch.group(2))!.toLowerCase();
      mode = switch (key) {
        'task' => AstraCommandMode.task,
        'calendar' => AstraCommandMode.calendar,
        'mail' => AstraCommandMode.mail,
        'panchang' => AstraCommandMode.panchang,
        _ => AstraCommandMode.none,
      };
      payload = normalized.substring(prefixMatch.end).trim();
    }

    // Strip timezone noise — temporal parser uses profile timezone.
    payload = payload.replaceAll(_timezoneNoise, '').replaceAll(RegExp(r'\s+'), ' ').trim();

    return NormalizedMessage(
      raw: raw,
      normalized: normalized,
      payload: payload,
      mode: mode,
    );
  }
}
