class Message {
  final String id;
  final String text;
  final String source; // 'whatsapp', 'manual'
  final DateTime receivedAt;
  final bool processed;
  final String? extractedJson;

  Message({
    required this.id,
    required this.text,
    required this.source,
    required this.receivedAt,
    this.processed = false,
    this.extractedJson,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'source': source,
        'receivedAt': receivedAt.toIso8601String(),
        'processed': processed,
        'extractedJson': extractedJson,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        text: json['text'],
        source: json['source'],
        receivedAt: DateTime.parse(json['receivedAt']),
        processed: json['processed'] ?? false,
        extractedJson: json['extractedJson'],
      );
}
