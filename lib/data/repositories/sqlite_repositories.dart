import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_progress.dart';
import '../models/lesson.dart';
import '../models/practice_result.dart';
import '../models/user_profile.dart';
import '../sources/database_helper.dart';
import 'contracts.dart';

class SqliteAuthRepository implements AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _activeUserId = 'usr_nguyen_anh';

  @override
  Future<UserProfile> getCurrentUser() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [_activeUserId],
    );

    if (maps.isNotEmpty) {
      return _mapToUser(maps.first);
    }

    final all = await getAvailableUsers();
    if (all.isNotEmpty) {
      _activeUserId = all.first.id;
      return all.first;
    }

    // Default fallback
    final defaultUser = UserProfile(
      id: 'usr_nguyen_anh',
      name: 'Nguyên Anh (Nhóm trưởng)',
      email: 'nguyenanh@example.com',
      streakCount: 5,
      dailyGoalMinutes: 5,
      reminderTime: '20:00',
      isReminderEnabled: true,
      level: 'Intermediate',
      totalSessions: 12,
      totalActiveMinutes: 64,
    );
    await updateProfile(defaultUser);
    return defaultUser;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    final db = await _dbHelper.database;
    await db.insert(
      'users',
      _userToMap(profile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (_activeUserId == profile.id) {
      _activeUserId = profile.id;
    }
  }

  @override
  Future<List<UserProfile>> getAvailableUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', orderBy: 'name ASC');
    return maps.map(_mapToUser).toList();
  }

  @override
  Future<void> switchUser(String userId) async {
    _activeUserId = userId;
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String level,
    required int dailyGoalMinutes,
  }) async {
    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserProfile(
      id: newId,
      name: name,
      email: email,
      streakCount: 0,
      dailyGoalMinutes: dailyGoalMinutes,
      reminderTime: '20:00',
      isReminderEnabled: true,
      level: level,
      totalSessions: 0,
      totalActiveMinutes: 0,
    );
    await updateProfile(newUser);
    _activeUserId = newId;
  }

  Future<void> deleteUser(String userId) async {
    final db = await _dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    final remaining = await getAvailableUsers();
    if (remaining.isNotEmpty) {
      _activeUserId = remaining.first.id;
    }
  }

  UserProfile _mapToUser(Map<String, dynamic> m) {
    return UserProfile(
      id: m['id'] as String,
      name: m['name'] as String,
      email: m['email'] as String,
      avatarUrl: m['avatar_url'] as String?,
      streakCount: (m['streak_count'] as num?)?.toInt() ?? 0,
      lastPracticeDate: m['last_practice_date'] as String?,
      dailyGoalMinutes: (m['daily_goal_minutes'] as num?)?.toInt() ?? 5,
      reminderTime: m['reminder_time'] as String? ?? '20:00',
      isReminderEnabled: (m['is_reminder_enabled'] as int?) == 1,
      level: m['level'] as String? ?? 'Beginner',
      totalSessions: (m['total_sessions'] as num?)?.toInt() ?? 0,
      totalActiveMinutes: (m['total_active_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _userToMap(UserProfile u) {
    return {
      'id': u.id,
      'name': u.name,
      'email': u.email,
      'avatar_url': u.avatarUrl,
      'streak_count': u.streakCount,
      'last_practice_date': u.lastPracticeDate,
      'daily_goal_minutes': u.dailyGoalMinutes,
      'reminder_time': u.reminderTime,
      'is_reminder_enabled': u.isReminderEnabled ? 1 : 0,
      'level': u.level,
      'total_sessions': u.totalSessions,
      'total_active_minutes': u.totalActiveMinutes,
    };
  }
}

class SqliteLessonRepository implements LessonRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<Lesson>> getLessons() async {
    final db = await _dbHelper.database;
    final maps = await db.query('lessons', orderBy: 'level ASC');
    return maps.map(_mapToLesson).toList();
  }

  @override
  Future<Lesson?> getLessonById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('lessons', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return _mapToLesson(maps.first);
    return null;
  }

  @override
  Future<List<Lesson>> getLessonsByLevel(String level) async {
    final all = await getLessons();
    if (level.isEmpty || level == 'All') return all;
    return all.where((l) => l.level.toLowerCase() == level.toLowerCase()).toList();
  }

  Lesson _mapToLesson(Map<String, dynamic> m) {
    List<String> targetPhonemes = [];
    try {
      final decoded = json.decode(m['target_phonemes'] as String);
      if (decoded is List) {
        targetPhonemes = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return Lesson(
      id: m['id'] as String,
      title: m['title'] as String,
      level: m['level'] as String,
      category: m['category'] as String,
      text: m['text'] as String,
      ipa: m['ipa'] as String,
      translationVi: m['translation_vi'] as String,
      audioSampleUrl: m['audio_sample_url'] as String,
      targetPhonemes: targetPhonemes,
    );
  }
}

class SqlitePracticeRepository implements PracticeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<void> savePracticeResult(PracticeResult result) async {
    final db = await _dbHelper.database;
    await db.insert(
      'practice_sessions',
      {
        'session_id': result.sessionId,
        'lesson_id': result.lessonId,
        'user_id': result.userId,
        'completed_at': result.completedAt,
        'active_duration_seconds': result.activeDurationSeconds,
        'status': result.status,
        'overall_score': result.scores.overall,
        'accuracy_score': result.scores.accuracy,
        'fluency_score': result.scores.fluency,
        'completeness_score': result.scores.completeness,
        'transcript': result.transcript,
        'target_text': result.targetText,
        'words_json': json.encode(result.words.map((w) => w.toJson()).toList()),
        'feedback_tips_json': json.encode(result.feedbackTips),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<PracticeResult?> getSessionResult(String sessionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'practice_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    if (maps.isNotEmpty) return _mapToResult(maps.first);
    return null;
  }

  @override
  Future<List<PracticeResult>> getHistory(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'practice_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );
    return maps.map(_mapToResult).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'practice_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<void> clearHistory(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'practice_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> clearAllHistory(String userId) => clearHistory(userId);

  PracticeResult _mapToResult(Map<String, dynamic> m) {
    List<WordEvaluation> words = [];
    try {
      final decodedWords = json.decode(m['words_json'] as String);
      if (decodedWords is List) {
        words = decodedWords
            .map((w) => WordEvaluation.fromJson(w as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    List<String> tips = [];
    try {
      final decodedTips = json.decode(m['feedback_tips_json'] as String);
      if (decodedTips is List) {
        tips = decodedTips.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return PracticeResult(
      sessionId: m['session_id'] as String,
      lessonId: m['lesson_id'] as String,
      userId: m['user_id'] as String,
      completedAt: m['completed_at'] as String,
      activeDurationSeconds: (m['active_duration_seconds'] as num?)?.toInt() ?? 0,
      status: m['status'] as String? ?? 'completed',
      scores: ScoreBreakdown(
        overall: (m['overall_score'] as num?)?.toDouble(),
        accuracy: (m['accuracy_score'] as num?)?.toDouble(),
        fluency: (m['fluency_score'] as num?)?.toDouble(),
        completeness: (m['completeness_score'] as num?)?.toDouble(),
      ),
      transcript: m['transcript'] as String? ?? '',
      targetText: m['target_text'] as String? ?? '',
      words: words,
      feedbackTips: tips,
    );
  }
}

class SqliteStreakProgressRepository implements StreakProgressRepository {
  final PracticeRepository _practiceRepo;
  final AuthRepository _authRepo;

  SqliteStreakProgressRepository({
    required PracticeRepository practiceRepo,
    required AuthRepository authRepo,
  })  : _practiceRepo = practiceRepo,
        _authRepo = authRepo;

  @override
  Future<DailyProgress> getTodayProgress(String userId) async {
    final user = await _authRepo.getCurrentUser();
    final history = await _practiceRepo.getHistory(userId);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    int todayActiveSeconds = 0;
    int practiceCount = 0;

    for (final session in history) {
      final sessionDate = DateTime.tryParse(session.completedAt)?.toLocal();
      if (sessionDate != null) {
        final sessionDateStr = DateFormat('yyyy-MM-dd').format(sessionDate);
        if (sessionDateStr == todayStr) {
          todayActiveSeconds += session.activeDurationSeconds;
          practiceCount++;
        }
      }
    }

    final targetSeconds = user.dailyGoalMinutes * 60;
    return DailyProgress(
      date: todayStr,
      activeSeconds: todayActiveSeconds,
      targetSeconds: targetSeconds,
      isGoalReached: todayActiveSeconds >= targetSeconds,
      practiceCount: practiceCount,
    );
  }

  @override
  Future<List<DailyProgress>> getWeeklyProgress(String userId) async {
    final user = await _authRepo.getCurrentUser();
    final history = await _practiceRepo.getHistory(userId);
    final targetSeconds = user.dailyGoalMinutes * 60;

    final now = DateTime.now();
    final List<DailyProgress> weekly = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);

      int activeSeconds = 0;
      int count = 0;

      for (final s in history) {
        final d = DateTime.tryParse(s.completedAt)?.toLocal();
        if (d != null && DateFormat('yyyy-MM-dd').format(d) == dayStr) {
          activeSeconds += s.activeDurationSeconds;
          count++;
        }
      }

      weekly.add(
        DailyProgress(
          date: dayStr,
          activeSeconds: activeSeconds,
          targetSeconds: targetSeconds,
          isGoalReached: activeSeconds >= targetSeconds,
          practiceCount: count,
        ),
      );
    }
    return weekly;
  }

  @override
  Future<void> updateDailyGoal(String userId, int minutes) async {
    final user = await _authRepo.getCurrentUser();
    await _authRepo.updateProfile(user.copyWith(dailyGoalMinutes: minutes));
  }

  @override
  Future<int> recalculateStreak(String userId) async {
    final user = await _authRepo.getCurrentUser();
    final history = await _practiceRepo.getHistory(userId);
    final targetSeconds = user.dailyGoalMinutes * 60;

    final Map<String, int> durationByDate = {};
    for (final s in history) {
      final d = DateTime.tryParse(s.completedAt)?.toLocal();
      if (d != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(d);
        durationByDate[dateKey] = (durationByDate[dateKey] ?? 0) + s.activeDurationSeconds;
      }
    }

    int streak = 0;
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);

    bool startFromToday = (durationByDate[todayKey] ?? 0) >= targetSeconds;
    DateTime checkDay = startFromToday ? today : today.subtract(const Duration(days: 1));

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(checkDay);
      final seconds = durationByDate[key] ?? 0;
      if (seconds >= targetSeconds) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (user.streakCount != streak) {
      await _authRepo.updateProfile(user.copyWith(streakCount: streak));
    }
    return streak;
  }
}
