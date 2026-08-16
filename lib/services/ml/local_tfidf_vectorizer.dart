import 'dart:math' as math;

/// Portable TF-IDF Vectorizer in pure Dart matching scikit-learn's TfidfVectorizer.
class LocalTfidfVectorizer {
  final bool lowercase;
  final List<int> ngramRange;
  final bool sublinearTf;
  final String norm;
  final bool useIdf;
  final bool smoothIdf;
  final Map<String, int> vocabulary;
  final List<double> idf;

  LocalTfidfVectorizer({
    this.lowercase = true,
    this.ngramRange = const [1, 2],
    this.sublinearTf = true,
    this.norm = 'l2',
    this.useIdf = true,
    this.smoothIdf = true,
    required this.vocabulary,
    required this.idf,
  });

  factory LocalTfidfVectorizer.fromJson(Map<String, dynamic> json) {
    final vocabJson = json['vocabulary'] as Map<String, dynamic>;
    final vocab = <String, int>{};
    for (final e in vocabJson.entries) {
      vocab[e.key] = (e.value as num).toInt();
    }

    final idfList = (json['idf'] as List<dynamic>)
        .map((x) => (x as num).toDouble())
        .toList(growable: false);

    final ngrams = (json['ngram_range'] as List<dynamic>?)
            ?.map((x) => (x as num).toInt())
            .toList() ??
        [1, 2];

    return LocalTfidfVectorizer(
      lowercase: json['lowercase'] as bool? ?? true,
      ngramRange: ngrams,
      sublinearTf: json['sublinear_tf'] as bool? ?? true,
      norm: json['norm'] as String? ?? 'l2',
      useIdf: json['use_idf'] as bool? ?? true,
      smoothIdf: json['smooth_idf'] as bool? ?? true,
      vocabulary: vocab,
      idf: idfList,
    );
  }

  /// Tokenizes string using scikit-learn's default token_pattern: (?u)\b\w\w+\b
  List<String> _tokenize(String text) {
    final s = lowercase ? text.toLowerCase() : text;
    // (?u)\b\w\w+\b matches 2 or more alphanumeric/underscore word characters
    final pattern = RegExp(r'\b\w\w+\b');
    return pattern.allMatches(s).map((m) => m.group(0)!).toList();
  }

  /// Extracts unigrams + bigrams (or ngrams according to ngramRange)
  List<String> _extractNgrams(List<String> tokens) {
    final minN = ngramRange.isNotEmpty ? ngramRange[0] : 1;
    final maxN = ngramRange.length > 1 ? ngramRange[1] : 1;

    final ngrams = <String>[];
    for (int n = minN; n <= maxN; n++) {
      for (int i = 0; i <= tokens.length - n; i++) {
        ngrams.add(tokens.sublist(i, i + n).join(' '));
      }
    }
    return ngrams;
  }

  /// Transforms [text] into a dense double vector corresponding to vocabulary features.
  List<double> transform(String text) {
    final tokens = _tokenize(text);
    final ngrams = _extractNgrams(tokens);

    // Compute raw term counts for vocabulary terms
    final termCounts = <int, int>{};
    for (final term in ngrams) {
      final index = vocabulary[term];
      if (index != null) {
        termCounts[index] = (termCounts[index] ?? 0) + 1;
      }
    }

    final featureCount = idf.length;
    final result = List<double>.filled(featureCount, 0.0);

    for (final entry in termCounts.entries) {
      final index = entry.key;
      final count = entry.value;

      // Sublinear TF: 1 + log(tf) if sublinear_tf is true, else tf
      double tf = count.toDouble();
      if (sublinearTf && count > 0) {
        tf = 1.0 + math.log(tf);
      }

      // TF * IDF
      final idfVal = useIdf ? idf[index] : 1.0;
      result[index] = tf * idfVal;
    }

    // Normalization (L2 norm by default in scikit-learn)
    if (norm == 'l2') {
      double sumSquares = 0.0;
      for (int i = 0; i < featureCount; i++) {
        sumSquares += result[i] * result[i];
      }
      if (sumSquares > 0.0) {
        final l2Norm = math.sqrt(sumSquares);
        for (int i = 0; i < featureCount; i++) {
          result[i] /= l2Norm;
        }
      }
    }

    return result;
  }
}
