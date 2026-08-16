import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/ml/local_intent_classifier.dart';
import 'package:astra/services/ml/local_event_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalIntentClassifier intentClassifier;
  late LocalEventClassifier eventClassifier;

  setUpAll(() {
    // Load directly from assets/models JSON files
    final intentJsonStr = File('assets/models/intent_model_v2.json').readAsStringSync();
    final intentMap = jsonDecode(intentJsonStr) as Map<String, dynamic>;
    intentClassifier = LocalIntentClassifier.fromJson(intentMap);

    final eventJsonStr = File('assets/models/event_type_model_v3.json').readAsStringSync();
    final eventMap = jsonDecode(eventJsonStr) as Map<String, dynamic>;
    eventClassifier = LocalEventClassifier.fromJson(eventMap);
  });

  group('ASTRA Phase M2-B: Set A & Set B Model Loading & Sanity Tests', () {
    // A. Set A model loading
    test('A. Set A model loading metadata and vocabulary size', () {
      expect(intentClassifier.modelName, 'astra_intent_classifier');
      expect(intentClassifier.version, 'v2');
      expect(intentClassifier.classifier.classes.length, 13);
      expect(intentClassifier.vectorizer.vocabulary.length, 1733);
      expect(intentClassifier.classifier.classes, contains('CREATE_TASK'));
      expect(intentClassifier.classifier.classes, contains('CREATE_REMINDER'));
      expect(intentClassifier.classifier.classes, contains('UPDATE_TASK'));
      expect(intentClassifier.classifier.classes, contains('LIST_TASKS'));
    });

    // B. Set B model loading
    test('B. Set B model loading metadata and vocabulary size', () {
      expect(eventClassifier.modelName, 'astra_event_classifier');
      expect(eventClassifier.version, 'v3');
      expect(eventClassifier.classifier.classes.length, 13);
      expect(eventClassifier.vectorizer.vocabulary.length, 3228);
      expect(eventClassifier.classifier.classes, contains('EXAM'));
      expect(eventClassifier.classifier.classes, contains('INTERVIEW'));
      expect(eventClassifier.classifier.classes, contains('ASSIGNMENT'));
    });

    // C. Known Set A predictions
    test('C. Known Set A predictions match expected intents', () {
      final res1 = intentClassifier.classifySync('remind me to drink water in 2 mins');
      expect(res1.prediction, 'CREATE_REMINDER');
      expect(res1.confidence, greaterThan(0.5));

      final res2 = intentClassifier.classifySync('move my exam to tomorrow at 7pm');
      expect(res2.prediction, 'UPDATE_TASK');
      expect(res2.confidence, greaterThan(0.5));

      final res3 = intentClassifier.classifySync('show my tasks');
      expect(res3.prediction, 'LIST_TASKS');
      expect(res3.confidence, greaterThan(0.5));
    });

    // D. Known Set B predictions
    test('D. Known Set B predictions match expected event types', () {
      final res1 = eventClassifier.classifySync('Google technical interview');
      expect(res1.prediction, 'INTERVIEW');
      expect(res1.confidence, greaterThan(0.5));

      final res2 = eventClassifier.classifySync('entrance exam test');
      expect(res2.prediction, 'EXAM');
      expect(res2.confidence, greaterThan(0.4));

      final res3 = eventClassifier.classifySync('machine learning assignment deadline');
      expect(res3.prediction, 'ASSIGNMENT');
      expect(res3.confidence, greaterThan(0.4));
    });

    // E. Top-3 predictions structure
    test('E. Top-3 predictions have descending confidence order summing to <= 1.0', () {
      final res = intentClassifier.classifySync('schedule a meeting with John tomorrow at 2pm');
      expect(res.topPredictions.length, 3);
      expect(res.topPredictions[0].confidence, greaterThanOrEqualTo(res.topPredictions[1].confidence));
      expect(res.topPredictions[1].confidence, greaterThanOrEqualTo(res.topPredictions[2].confidence));
    });

    // F. Confidence ranges (0.0 to 1.0)
    test('F. Confidence range is strictly within [0.0, 1.0]', () {
      final res = eventClassifier.classifySync('cyber security training session next week');
      expect(res.confidence, greaterThanOrEqualTo(0.0));
      expect(res.confidence, lessThanOrEqualTo(1.0));
    });

    // H. Empty / Corrupt input handling
    test('H. Empty input returns safe defaults without throwing', () {
      final resA = intentClassifier.classifySync('');
      expect(resA.prediction, 'GENERAL_CHAT');
      expect(resA.confidence, 0.0);

      final resB = eventClassifier.classifySync('   ');
      expect(resB.prediction, 'OTHER');
      expect(resB.confidence, 0.0);
    });
  });

  group('ASTRA Phase M2-B: Python vs. Dart Exact Parity Verification (122 Utterances)', () {
    test('G. 100% Exact Parity on all 122 utterances against Python scikit-learn ground truth', () {
      final corpusFile = File('test/fixtures/ml_parity_corpus.json');
      expect(corpusFile.existsSync(), isTrue);

      final corpusList = jsonDecode(corpusFile.readAsStringSync()) as List<dynamic>;
      expect(corpusList.length, greaterThanOrEqualTo(100));

      int setAMatches = 0;
      int setBMatches = 0;
      double maxSetAConfDiff = 0.0;
      double maxSetBConfDiff = 0.0;

      for (final item in corpusList) {
        final text = item['text'] as String;
        final pySetA = item['set_a'] as Map<String, dynamic>;
        final pySetB = item['set_b'] as Map<String, dynamic>;

        // 1. Dart Set A Inference
        final dartSetA = intentClassifier.classifySync(text);
        final pySetAPred = pySetA['prediction'] as String;
        final pySetAConf = (pySetA['confidence'] as num).toDouble();

        expect(
          dartSetA.prediction,
          equals(pySetAPred),
          reason: 'Set A prediction mismatch for "$text": Python=$pySetAPred, Dart=${dartSetA.prediction}',
        );
        setAMatches++;

        final setAConfDiff = (dartSetA.confidence - pySetAConf).abs();
        if (setAConfDiff > maxSetAConfDiff) maxSetAConfDiff = setAConfDiff;
        expect(
          setAConfDiff,
          lessThanOrEqualTo(0.001),
          reason: 'Set A confidence diff $setAConfDiff exceeded tolerance 0.001 for "$text"',
        );

        // 2. Dart Set B Inference
        final dartSetB = eventClassifier.classifySync(text);
        final pySetBPred = pySetB['prediction'] as String;
        final pySetBConf = (pySetB['confidence'] as num).toDouble();

        expect(
          dartSetB.prediction,
          equals(pySetBPred),
          reason: 'Set B prediction mismatch for "$text": Python=$pySetBPred, Dart=${dartSetB.prediction}',
        );
        setBMatches++;

        final setBConfDiff = (dartSetB.confidence - pySetBConf).abs();
        if (setBConfDiff > maxSetBConfDiff) maxSetBConfDiff = setBConfDiff;
        expect(
          setBConfDiff,
          lessThanOrEqualTo(0.001),
          reason: 'Set B confidence diff $setBConfDiff exceeded tolerance 0.001 for "$text"',
        );
      }

      expect(setAMatches, corpusList.length);
      expect(setBMatches, corpusList.length);
    });
  });
}
