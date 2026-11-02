import 'package:flutter_test/flutter_test.dart';
import 'package:th3_ai_pronunciation/data/services/phoneme_ai_evaluator.dart';

void main() {
  group('PhonemeAiEvaluator Unit Tests', () {
    test('Tokenize IPA accurately splits compound and single phonemes', () {
      final tokens = PhonemeAiEvaluator.tokenizeIpa('θɪŋk');
      expect(tokens, contains('θ'));
      expect(tokens, contains('ɪ'));

      final vowelLongTokens = PhonemeAiEvaluator.tokenizeIpa('ʃiːp');
      expect(vowelLongTokens, contains('ʃ'));
      expect(vowelLongTokens, contains('iː'));
      expect(vowelLongTokens, contains('p'));
    });

    test('Phonetic similarity matrix detects common learner confusion pairs', () {
      // /θ/ vs /s/
      final simThetaS = PhonemeAiEvaluator.getPhoneticSimilarity('θ', 's');
      expect(simThetaS, greaterThanOrEqualTo(0.6));
      expect(simThetaS, lessThan(0.8));

      // /θ/ vs /θ/ identical
      final simIdentical = PhonemeAiEvaluator.getPhoneticSimilarity('θ', 'θ');
      expect(simIdentical, equals(1.0));

      // /iː/ vs /ɪ/
      final simVowelLongShort = PhonemeAiEvaluator.getPhoneticSimilarity('iː', 'ɪ');
      expect(simVowelLongShort, greaterThanOrEqualTo(0.6));
    });

    test('Evaluation of perfect speech produces high overall score', () {
      final result = PhonemeAiEvaluator.evaluate(
        targetText: 'I think this is the right path.',
        expectedIpa: '/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/',
        spokenText: 'I think this is the right path',
        lessonId: 'les_001',
        activeDurationSeconds: 4,
      );

      expect(result.scores.overall, isNotNull);
      expect(result.scores.overall!, greaterThanOrEqualTo(85.0));
      expect(result.words.length, equals(7));
      expect(result.words.every((w) => w.status == 'correct'), isTrue);
      expect(result.feedbackTips.isNotEmpty, isTrue);
    });

    test('Evaluation of mispronounced words detects mistakes and generates targeted tips', () {
      // Simulates learner saying "I sink dis is de right pat"
      final result = PhonemeAiEvaluator.evaluate(
        targetText: 'I think this is the right path.',
        expectedIpa: '/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/',
        spokenText: 'I sink dis is de right pat',
        lessonId: 'les_001',
        activeDurationSeconds: 4,
      );

      expect(result.scores.overall, isNotNull);
      expect(result.scores.overall!, lessThan(80.0));

      // Check that "think" was flagged as incorrect or warning
      final thinkEval = result.words.firstWhere((w) => w.word == 'think');
      expect(thinkEval.status != 'correct', isTrue);

      // Check feedback mentions /θ/ or mouth placement
      final hasTipForTheta = result.feedbackTips.any((tip) => tip.contains('/θ/') || tip.contains('lưỡi'));
      expect(hasTipForTheta, isTrue);
    });

    test('Simulate low score mode works as expected for QA/TV3', () {
      final result = PhonemeAiEvaluator.evaluate(
        targetText: 'I think this is the right path.',
        expectedIpa: '/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/',
        spokenText: '',
        lessonId: 'les_001',
        activeDurationSeconds: 3,
        simulateLowScore: true,
      );

      expect(result.scores.overall, equals(58.0));
      expect(result.words.any((w) => w.status == 'incorrect'), isTrue);
    });
  });
}
