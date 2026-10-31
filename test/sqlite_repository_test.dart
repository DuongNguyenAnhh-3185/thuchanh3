import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:th3_ai_pronunciation/data/models/practice_result.dart';
import 'package:th3_ai_pronunciation/data/repositories/sqlite_repositories.dart';
import 'package:th3_ai_pronunciation/data/sources/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper().close();
  });

  group('SQLite Repositories Integration Tests', () {
    late SqliteAuthRepository authRepo;
    late SqliteLessonRepository lessonRepo;
    late SqlitePracticeRepository practiceRepo;

    setUp(() {
      authRepo = SqliteAuthRepository();
      lessonRepo = SqliteLessonRepository();
      practiceRepo = SqlitePracticeRepository();
    });

    test('AuthRepository: retrieve users and switch active user', () async {
      final users = await authRepo.getAvailableUsers();
      expect(users.isNotEmpty, isTrue);

      final currentUser = await authRepo.getCurrentUser();
      expect(currentUser.id, isNotEmpty);

      // Switch to a new or existing user
      final targetUser = users.first;
      await authRepo.switchUser(targetUser.id);
      final activeAfterSwitch = await authRepo.getCurrentUser();
      expect(activeAfterSwitch.id, equals(targetUser.id));
    });

    test('AuthRepository: update profile changes persist in database', () async {
      final currentUser = await authRepo.getCurrentUser();
      final updated = currentUser.copyWith(
        streakCount: currentUser.streakCount + 1,
        dailyGoalMinutes: 10,
      );

      await authRepo.updateProfile(updated);
      final refreshed = await authRepo.getCurrentUser();
      expect(refreshed.streakCount, equals(currentUser.streakCount + 1));
      expect(refreshed.dailyGoalMinutes, equals(10));
    });

    test('LessonRepository: can query seeded lessons and filter by level', () async {
      final allLessons = await lessonRepo.getLessons();
      expect(allLessons.isNotEmpty, isTrue);

      final first = allLessons.first;
      final byId = await lessonRepo.getLessonById(first.id);
      expect(byId, isNotNull);
      expect(byId!.id, equals(first.id));

      final beginners = await lessonRepo.getLessonsByLevel('Beginner');
      expect(beginners.every((l) => l.level == 'Beginner'), isTrue);
    });

    test('PracticeRepository: save, retrieve, idempotency, and delete session', () async {
      const testSessionId = 'test_sess_sqlite_999';
      const testUserId = 'usr_test_sqlite';

      final sampleResult = PracticeResult(
        sessionId: testSessionId,
        lessonId: 'les_001',
        userId: testUserId,
        completedAt: DateTime.now().toUtc().toIso8601String(),
        activeDurationSeconds: 25,
        status: 'completed',
        scores: ScoreBreakdown(
          overall: 88.5,
          accuracy: 90.0,
          fluency: 85.0,
          completeness: 92.0,
        ),
        transcript: 'I think this is the right path',
        targetText: 'I think this is the right path.',
        words: [],
        feedbackTips: ['Tập trung vào âm /θ/'],
      );

      // 1. Save result
      await practiceRepo.savePracticeResult(sampleResult);

      // 2. Retrieve by sessionId
      final retrieved = await practiceRepo.getSessionResult(testSessionId);
      expect(retrieved, isNotNull);
      expect(retrieved!.sessionId, equals(testSessionId));
      expect(retrieved.scores.overall, equals(88.5));
      expect(retrieved.activeDurationSeconds, equals(25));

      // 3. Idempotent update: saving with same sessionId updates existing row
      final updatedResult = sampleResult.copyWith(
        scores: ScoreBreakdown(overall: 95.0, accuracy: 96.0, fluency: 94.0, completeness: 95.0),
      );
      await practiceRepo.savePracticeResult(updatedResult);
      final history = await practiceRepo.getHistory(testUserId);
      final sessionMatches = history.where((s) => s.sessionId == testSessionId).toList();
      expect(sessionMatches.length, equals(1));
      expect(sessionMatches.first.scores.overall, equals(95.0));

      // 4. Delete session
      await practiceRepo.deleteSession(testSessionId);
      final afterDelete = await practiceRepo.getSessionResult(testSessionId);
      expect(afterDelete, isNull);
    });

    test('PracticeRepository: clearHistory deletes all sessions for specific user', () async {
      const clearUser = 'usr_to_clear';
      final s1 = PracticeResult(
        sessionId: 'clear_sess_1',
        lessonId: 'les_001',
        userId: clearUser,
        completedAt: DateTime.now().toUtc().toIso8601String(),
        activeDurationSeconds: 10,
        status: 'completed',
        scores: ScoreBreakdown(overall: 80.0),
        transcript: '',
        targetText: 'Test',
        words: [],
        feedbackTips: [],
      );
      final s2 = PracticeResult(
        sessionId: 'clear_sess_2',
        lessonId: 'les_002',
        userId: clearUser,
        completedAt: DateTime.now().toUtc().toIso8601String(),
        activeDurationSeconds: 15,
        status: 'completed',
        scores: ScoreBreakdown(overall: 85.0),
        transcript: '',
        targetText: 'Test 2',
        words: [],
        feedbackTips: [],
      );

      await practiceRepo.savePracticeResult(s1);
      await practiceRepo.savePracticeResult(s2);

      final userHistoryBefore = await practiceRepo.getHistory(clearUser);
      expect(userHistoryBefore.length, greaterThanOrEqualTo(2));

      await practiceRepo.clearHistory(clearUser);
      final userHistoryAfter = await practiceRepo.getHistory(clearUser);
      expect(userHistoryAfter.isEmpty, isTrue);
    });
  });
}
