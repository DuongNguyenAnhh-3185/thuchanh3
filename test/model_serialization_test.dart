import 'package:flutter_test/flutter_test.dart';
import 'package:th3_ai_pronunciation/data/models/lesson.dart';
import 'package:th3_ai_pronunciation/data/models/practice_result.dart';
import 'package:th3_ai_pronunciation/data/models/user_profile.dart';

void main() {
  group('Model Serialization & Null-Safety Tests', () {
    test('UserProfile parses from JSON correctly', () {
      final jsonMap = {
        'id': 'usr_001',
        'name': 'Le Van C',
        'email': 'levanc@example.com',
        'streakCount': 12,
        'dailyGoalMinutes': 10,
        'reminderTime': '21:00',
        'isReminderEnabled': true,
        'level': 'Advanced',
        'totalSessions': 45,
        'totalActiveMinutes': 210,
      };

      final profile = UserProfile.fromJson(jsonMap);
      expect(profile.id, equals('usr_001'));
      expect(profile.streakCount, equals(12));
      expect(profile.dailyGoalMinutes, equals(10));
      expect(profile.level, equals('Advanced'));
    });

    test('Lesson parses targetPhonemes list properly', () {
      final jsonMap = {
        'id': 'les_001',
        'title': 'Voiceless TH /θ/',
        'level': 'Beginner',
        'category': 'Consonants',
        'text': 'I think this is the right path.',
        'ipa': '/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/',
        'translationVi': 'Tôi nghĩ đây là con đường đúng đắn.',
        'audioSampleUrl': 'assets/audio/les_001.mp3',
        'targetPhonemes': ['θ', 'ð', 'p'],
      };

      final lesson = Lesson.fromJson(jsonMap);
      expect(lesson.id, equals('les_001'));
      expect(lesson.targetPhonemes.length, equals(3));
      expect(lesson.targetPhonemes.first, equals('θ'));
    });

    test('PracticeResult parses phoneme comparison correctly', () {
      final jsonMap = {
        'sessionId': 'sess_test_1',
        'lessonId': 'les_001',
        'userId': 'usr_001',
        'completedAt': '2026-10-31T09:15:30.000Z',
        'activeDurationSeconds': 14,
        'status': 'completed',
        'scores': {
          'overall': 54.0,
          'accuracy': 52.0,
          'fluency': 58.0,
          'completeness': 92.0,
        },
        'transcript': 'I sink this is the right pat',
        'targetText': 'I think this is the right path.',
        'words': [
          {
            'word': 'think',
            'ipa': '/θɪŋk/',
            'score': 42.0,
            'status': 'incorrect',
            'phonemes': [
              {
                'phoneme': 'θ',
                'ipaExpected': 'θ',
                'ipaActual': 's',
                'score': 25.0,
                'isCorrect': false,
              }
            ],
          }
        ],
        'feedbackTips': ['Lỗi âm /θ/ trong think'],
      };

      final result = PracticeResult.fromJson(jsonMap);
      expect(result.scores.overall, equals(54.0));
      expect(result.words.length, equals(1));

      final word = result.words.first;
      expect(word.status, equals('incorrect'));
      expect(word.phonemes.length, equals(1));

      final phoneme = word.phonemes.first;
      expect(phoneme.ipaExpected, equals('θ'));
      expect(phoneme.ipaActual, equals('s'));
      expect(phoneme.isCorrect, isFalse);
    });

    test('PracticeResult handles null sub-scores safely without crashing', () {
      final jsonMap = {
        'sessionId': 'sess_partial',
        'lessonId': 'les_002',
        'userId': 'usr_001',
        'completedAt': '2026-10-31T09:15:30.000Z',
        'activeDurationSeconds': 10,
        'status': 'completed',
        'scores': {
          'overall': 75.0,
          'accuracy': null,
          'fluency': null,
          'completeness': null,
        },
        'transcript': 'My mother',
        'targetText': 'My mother',
        'words': [],
        'feedbackTips': [],
      };

      final result = PracticeResult.fromJson(jsonMap);
      expect(result.scores.overall, equals(75.0));
      expect(result.scores.accuracy, isNull);
      expect(result.scores.fluency, isNull);
      expect(result.scores.completeness, isNull);
    });
  });
}
