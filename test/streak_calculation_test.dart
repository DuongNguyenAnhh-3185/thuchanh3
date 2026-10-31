import 'package:flutter_test/flutter_test.dart';
import 'package:th3_ai_pronunciation/data/models/practice_result.dart';
import 'package:th3_ai_pronunciation/data/models/user_profile.dart';
import 'package:th3_ai_pronunciation/data/repositories/contracts.dart';
import 'package:th3_ai_pronunciation/data/repositories/mock_repositories.dart';

class TestAuthRepo implements AuthRepository {
  UserProfile user;
  TestAuthRepo(this.user);

  @override
  Future<UserProfile> getCurrentUser() async => user;
  @override
  Future<void> updateProfile(UserProfile profile) async => user = profile;
  @override
  Future<List<UserProfile>> getAvailableUsers() async => [user];
  @override
  Future<void> switchUser(String userId) async {}
}

class TestPracticeRepo implements PracticeRepository {
  final List<PracticeResult> sessions;
  TestPracticeRepo(this.sessions);

  @override
  Future<void> savePracticeResult(PracticeResult result) async => sessions.insert(0, result);
  @override
  Future<PracticeResult?> getSessionResult(String sessionId) async =>
      sessions.firstWhere((s) => s.sessionId == sessionId);
  @override
  Future<List<PracticeResult>> getHistory(String userId) async => sessions;
}

void main() {
  group('Streak Calculation Engine Tests', () {
    test('Calculates streak correctly for consecutive days reaching target', () async {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'usr_test',
        name: 'Test',
        email: 'test@example.com',
        streakCount: 0,
        dailyGoalMinutes: 5, // 300 seconds
        reminderTime: '20:00',
        isReminderEnabled: true,
        level: 'Beginner',
        totalSessions: 5,
        totalActiveMinutes: 30,
      );

      final auth = TestAuthRepo(user);
      final sessions = <PracticeResult>[];

      // Add 3 consecutive days reaching 310s each (Goal is 300s)
      for (int i = 0; i < 3; i++) {
        final d = now.subtract(Duration(days: i));
        sessions.add(
          PracticeResult(
            sessionId: 'sess_$i',
            lessonId: 'les_001',
            userId: 'usr_test',
            completedAt: d.toUtc().toIso8601String(),
            activeDurationSeconds: 310,
            status: 'completed',
            scores: ScoreBreakdown(overall: 90.0),
            transcript: 'test',
            targetText: 'test',
            words: [],
            feedbackTips: [],
          ),
        );
      }

      final practiceRepo = TestPracticeRepo(sessions);
      final streakRepo = MockStreakProgressRepository(
        practiceRepo: practiceRepo,
        authRepo: auth,
      );

      final calculatedStreak = await streakRepo.recalculateStreak('usr_test');
      expect(calculatedStreak, equals(3));
    });

    test('Multiple sessions on same day do not increase streak count more than once', () async {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'usr_test',
        name: 'Test',
        email: 'test@example.com',
        streakCount: 0,
        dailyGoalMinutes: 5,
        reminderTime: '20:00',
        isReminderEnabled: true,
        level: 'Beginner',
        totalSessions: 3,
        totalActiveMinutes: 20,
      );

      final auth = TestAuthRepo(user);
      final sessions = <PracticeResult>[
        // 3 separate sessions on the SAME day
        PracticeResult(
          sessionId: 's1',
          lessonId: 'les_001',
          userId: 'usr_test',
          completedAt: now.toUtc().toIso8601String(),
          activeDurationSeconds: 150,
          status: 'completed',
          scores: ScoreBreakdown(overall: 80.0),
          transcript: '',
          targetText: '',
          words: [],
          feedbackTips: [],
        ),
        PracticeResult(
          sessionId: 's2',
          lessonId: 'les_002',
          userId: 'usr_test',
          completedAt: now.subtract(const Duration(hours: 1)).toUtc().toIso8601String(),
          activeDurationSeconds: 200,
          status: 'completed',
          scores: ScoreBreakdown(overall: 85.0),
          transcript: '',
          targetText: '',
          words: [],
          feedbackTips: [],
        ),
      ];

      final practiceRepo = TestPracticeRepo(sessions);
      final streakRepo = MockStreakProgressRepository(
        practiceRepo: practiceRepo,
        authRepo: auth,
      );

      final calculatedStreak = await streakRepo.recalculateStreak('usr_test');
      // Total active duration is 150 + 200 = 350s >= 300s -> streak is 1, not 2
      expect(calculatedStreak, equals(1));
    });

    test('Streak resets if there is a gap day', () async {
      final now = DateTime.now();
      final user = UserProfile(
        id: 'usr_test',
        name: 'Test',
        email: 'test@example.com',
        streakCount: 0,
        dailyGoalMinutes: 5,
        reminderTime: '20:00',
        isReminderEnabled: true,
        level: 'Beginner',
        totalSessions: 2,
        totalActiveMinutes: 10,
      );

      final auth = TestAuthRepo(user);
      final sessions = <PracticeResult>[
        // Today practiced
        PracticeResult(
          sessionId: 's_today',
          lessonId: 'les_001',
          userId: 'usr_test',
          completedAt: now.toUtc().toIso8601String(),
          activeDurationSeconds: 320,
          status: 'completed',
          scores: ScoreBreakdown(overall: 85.0),
          transcript: '',
          targetText: '',
          words: [],
          feedbackTips: [],
        ),
        // Missed yesterday! Practiced 2 days ago:
        PracticeResult(
          sessionId: 's_2days_ago',
          lessonId: 'les_001',
          userId: 'usr_test',
          completedAt: now.subtract(const Duration(days: 2)).toUtc().toIso8601String(),
          activeDurationSeconds: 320,
          status: 'completed',
          scores: ScoreBreakdown(overall: 85.0),
          transcript: '',
          targetText: '',
          words: [],
          feedbackTips: [],
        ),
      ];

      final practiceRepo = TestPracticeRepo(sessions);
      final streakRepo = MockStreakProgressRepository(
        practiceRepo: practiceRepo,
        authRepo: auth,
      );

      final calculatedStreak = await streakRepo.recalculateStreak('usr_test');
      // Yesterday was missed, so streak is 1 (today only)
      expect(calculatedStreak, equals(1));
    });
  });
}
