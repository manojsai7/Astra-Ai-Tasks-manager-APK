/// ASTRA Email Classifier
///
/// A lightweight, zero-dependency rule-based classifier that scores
/// incoming emails and decides whether to auto-create a task,
/// ask the user to confirm, or silently ignore.
///
/// No NLP library needed — weighted keyword matching handles 90%+ of cases.
class EmailClassifier {
  // ─── Weighted Keyword Map ─────────────────────────────────────────────────
  // Positive weights → task-worthy signal
  // Negative weights → spam / noise signal
  static const Map<String, double> _weights = {
    // High-signal task keywords
    'deadline':        0.85,
    'due':             0.80,
    'due date':        0.80,
    'last date':       0.80,
    'apply by':        0.85,
    'submit by':       0.85,
    'register by':     0.80,
    'apply':           0.70,
    'application':     0.70,
    'submit':          0.70,
    'assignment':      0.70,
    'homework':        0.65,
    'project':         0.60,
    'register':        0.60,
    'registration':    0.60,
    'exam':            0.90,
    'test':            0.75,
    'quiz':            0.70,
    'assessment':      0.80,
    'interview':       0.80,
    'offer letter':    0.85,
    'selection':       0.70,
    'shortlisted':     0.75,
    'offer':           0.65,
    'reminder':        0.70,
    'action required': 0.85,
    'urgent':          0.80,
    'important':       0.60,
    'meeting':         0.50,
    'appointment':     0.60,
    'schedule':        0.50,
    'join':            0.45,
    'call':            0.40,
    'review':          0.40,

    // Negative-signal spam keywords
    'unsubscribe':    -0.80,
    'newsletter':     -0.70,
    'weekly digest':  -0.65,
    'daily digest':   -0.65,
    'promotional':    -0.60,
    'promotion':      -0.55,
    'discount':       -0.55,
    'sale':           -0.45,
    'offer ends':     -0.50,
    'shop now':       -0.60,
    'buy now':        -0.60,
    'click here':     -0.45,
    'social':         -0.35,
    'follow us':      -0.40,
    'no-reply':       -0.30,
    'noreply':        -0.30,
    'do not reply':   -0.30,
  };

  // ─── Classification Entry Point ───────────────────────────────────────────

  /// Classifies a single email given its [subject], [body], and [sender].
  ///
  /// Returns a [ClassificationResult] with a [score] in [0, 1],
  /// an [action] ('AUTO_CREATE' | 'CONFIRM' | 'IGNORE'),
  /// and a [reason] string useful for debugging.
  static ClassificationResult classify({
    required String subject,
    required String body,
    String sender = '',
  }) {
    final combined = '$subject $body $sender'.toLowerCase();
    final wordCount = combined.split(RegExp(r'\s+')).length.clamp(1, 9999);

    double rawScore = 0.0;
    final List<String> matched = [];

    for (final entry in _weights.entries) {
      if (combined.contains(entry.key)) {
        rawScore += entry.value;
        if (entry.value > 0) matched.add(entry.key);
      }
    }

    // Normalise: density decays score so short keyword-dense emails don't over-score.
    final density = (wordCount / 20.0).clamp(1.0, 10.0);
    double score = (rawScore / density).clamp(0.0, 1.0);

    // Boost: subject-line hits carry extra weight.
    for (final entry in _weights.entries) {
      if (entry.value > 0 && subject.toLowerCase().contains(entry.key)) {
        score = (score + 0.08).clamp(0.0, 1.0);
      }
    }

    final String action;
    if (score >= 0.65) {
      action = 'AUTO_CREATE';
    } else if (score >= 0.35) {
      action = 'CONFIRM';
    } else {
      action = 'IGNORE';
    }

    final reason = matched.isEmpty
        ? 'No task-worthy keywords detected'
        : 'Matched: ${matched.take(4).join(', ')}';

    return ClassificationResult(score: score, action: action, reason: reason);
  }
}

// ─── Result Model ─────────────────────────────────────────────────────────────

class ClassificationResult {
  /// Normalised confidence score in [0.0, 1.0].
  final double score;

  /// One of: 'AUTO_CREATE', 'CONFIRM', 'IGNORE'.
  final String action;

  /// Human-readable explanation (useful for logging / debugging).
  final String reason;

  const ClassificationResult({
    required this.score,
    required this.action,
    required this.reason,
  });

  bool get shouldAutoCreate => action == 'AUTO_CREATE';
  bool get shouldConfirm    => action == 'CONFIRM';
  bool get shouldIgnore     => action == 'IGNORE';
  int  get scorePercent     => (score * 100).toInt();

  @override
  String toString() =>
      'ClassificationResult(action: $action, score: $scorePercent%, reason: $reason)';

}
