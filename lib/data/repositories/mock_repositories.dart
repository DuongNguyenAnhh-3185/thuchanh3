import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../models/daily_progress.dart';
import '../models/lesson.dart';
import '../models/practice_result.dart';
import '../models/user_profile.dart';
import 'contracts.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile _currentUser = UserProfile(
    id: 'usr_dev_01',
    name: 'Nguyễn Văn A',
    email: 'nguyenvana@example.com',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150',
    streakCount: 5,
    lastPracticeDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    dailyGoalMinutes: 5,
    reminderTime: '20:00',
    isReminderEnabled: true,
    level: 'Intermediate',
    totalSessions: 28,
    totalActiveMinutes: 142,
  );

  final List<UserProfile> _availableUsers = [
    UserProfile(
      id: 'usr_dev_01',
      name: 'Nguyễn Văn A (Demo User)',
      email: 'nguyenvana@example.com',
      streakCount: 5,
      lastPracticeDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      dailyGoalMinutes: 5,
      reminderTime: '20:00',
      isReminderEnabled: true,
      level: 'Intermediate',
      totalSessions: 28,
      totalActiveMinutes: 142,
    ),
    UserProfile(
      id: 'usr_dev_02',
      name: 'Trần Thị B (New Learner)',
      email: 'tranthib@example.com',
      streakCount: 0,
      lastPracticeDate: null,
      dailyGoalMinutes: 3,
      reminderTime: '19:30',
      isReminderEnabled: false,
      level: 'Beginner',
      totalSessions: 2,
      totalActiveMinutes: 6,
    ),
  ];

  @override
  Future<UserProfile> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    final index = _availableUsers.indexWhere((u) => u.id == profile.id);
    if (index >= 0) {
      _availableUsers[index] = profile;
    }
  }

  @override
  Future<List<UserProfile>> getAvailableUsers() async {
    return _availableUsers;
  }

  @override
  Future<void> switchUser(String userId) async {
    final user = _availableUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => _availableUsers.first,
    );
    _currentUser = user;
  }
}

class MockLessonRepository implements LessonRepository {
  List<Lesson>? _cachedLessons;

  @override
  Future<List<Lesson>> getLessons() async {
    if (_cachedLessons != null && _cachedLessons!.isNotEmpty) {
      return _cachedLessons!;
    }

    try {
      final jsonString = await rootBundle.loadString(AppConstants.mockLessonsPath);
      final List<dynamic> list = json.decode(jsonString);
      _cachedLessons = list.map((item) => Lesson.fromJson(item as Map<String, dynamic>)).toList();
      return _cachedLessons!;
    } catch (_) {
      // Fallback data if bundle loading fails
      _cachedLessons = [
        Lesson(
          id: 'les_001',
          title: 'Voiceless TH /θ/ - Think & Thought',
          level: 'Beginner',
          category: 'Consonants',
          text: 'I think this is the right path.',
          ipa: '/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/',
          translationVi: 'Tôi nghĩ đây là con đường đúng đắn.',
          audioSampleUrl: 'assets/audio/les_001.mp3',
          targetPhonemes: ['θ', 'ð', 'p'],
        ),
        Lesson(
          id: 'les_002',
          title: 'Voiced TH /ð/ - Weather & Mother',
          level: 'Beginner',
          category: 'Consonants',
          text: 'My mother loves warm weather together.',
          ipa: '/maɪ ˈmʌðər lʌvz wɔːrm ˈwɛðər təˈɡɛðər/',
          translationVi: 'Mẹ tôi thích thời tiết ấm áp khi ở cùng nhau.',
          audioSampleUrl: 'assets/audio/les_002.mp3',
          targetPhonemes: ['ð', 'v', 'z'],
        ),
      ];
      return _cachedLessons!;
    }
  }

  @override
  Future<Lesson?> getLessonById(String id) async {
    final all = await getLessons();
    try {
      return all.firstWhere((l) => l.id == id);
    } catch (_) {
      return all.isNotEmpty ? all.first : null;
    }
  }

  @override
  Future<List<Lesson>> getLessonsByLevel(String level) async {
    final all = await getLessons();
    if (level.isEmpty || level == 'All') return all;
    return all.where((l) => l.level.toLowerCase() == level.toLowerCase()).toList();
  }
}

class MockPracticeRepository implements PracticeRepository {
  final List<PracticeResult> _sessions = [];
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final jsonString = await rootBundle.loadString(AppConstants.mockHistoryMultiPath);
      final List<dynamic> list = json.decode(jsonString);
      for (final item in list) {
        _sessions.add(PracticeResult.fromJson(item as Map<String, dynamic>));
      }
    } catch (_) {
      // Fallback in-memory session
      _sessions.add(
        PracticeResult(
          sessionId: 'sess_init_01',
          lessonId: 'les_001',
          userId: 'usr_dev_01',
          completedAt: DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
          activeDurationSeconds: 15,
          status: 'completed',
          scores: ScoreBreakdown(overall: 92.5, accuracy: 94.0, fluency: 90.0, completeness: 95.0),
          transcript: 'I think this is the right path',
          targetText: 'I think this is the right path.',
          words: [],
          feedbackTips: ['Phát âm rất tốt!'],
        ),
      );
    }
    _initialized = true;
  }

  @override
  Future<void> savePracticeResult(PracticeResult result) async {
    await _ensureInitialized();
    // Idempotent: replace if existing sessionId
    final index = _sessions.indexWhere((s) => s.sessionId == result.sessionId);
    if (index >= 0) {
      _sessions[index] = result;
    } else {
      _sessions.insert(0, result);
    }
  }

  @override
  Future<PracticeResult?> getSessionResult(String sessionId) async {
    await _ensureInitialized();
    try {
      return _sessions.firstWhere((s) => s.sessionId == sessionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PracticeResult>> getHistory(String userId) async {
    await _ensureInitialized();
    return List.unmodifiable(_sessions);
  }
}

class MockStreakProgressRepository implements StreakProgressRepository {
  final PracticeRepository _practiceRepo;
  final AuthRepository _authRepo;

  MockStreakProgressRepository({
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

    // Group active duration by local date
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

    // Check if today reached goal
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

class MockSpeechAiService implements SpeechAiService {
  @override
  Future<PracticeResult> evaluatePronunciation({
    required String audioFilePath,
    required String lessonId,
    required String targetText,
    required String expectedIpa,
    required int activeDurationSeconds,
    bool simulateError = false,
    bool simulateLowScore = false,
  }) async {
    // Simulate AI processing network delay (1.2s)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (simulateError) {
      throw Exception('SPEECH_NOT_DETECTED: Không nhận diện được giọng nói trong bản thu âm.');
    }

    final path = simulateLowScore
        ? AppConstants.mockResultLowPath
        : AppConstants.mockResultHighPath;

    try {
      final jsonString = await rootBundle.loadString(path);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      // Update with current session timestamp and actual duration
      data['sessionId'] = 'sess_${DateTime.now().millisecondsSinceEpoch}';
      data['lessonId'] = lessonId;
      data['activeDurationSeconds'] = activeDurationSeconds;
      data['completedAt'] = DateTime.now().toUtc().toIso8601String();
      return PracticeResult.fromJson(data);
    } catch (_) {
      // Inline fallback high score result
      return PracticeResult(
        sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        lessonId: lessonId,
        userId: 'usr_dev_01',
        completedAt: DateTime.now().toUtc().toIso8601String(),
        activeDurationSeconds: activeDurationSeconds,
        status: 'completed',
        scores: ScoreBreakdown(overall: 92.0, accuracy: 94.0, fluency: 90.0, completeness: 95.0),
        transcript: targetText,
        targetText: targetText,
        words: [
          WordEvaluation(
            word: 'Think',
            ipa: '/θɪŋk/',
            score: 92.0,
            status: 'correct',
            phonemes: [
              PhonemeEvaluation(
                phoneme: 'θ',
                ipaExpected: 'θ',
                ipaActual: 'θ',
                score: 91.0,
                isCorrect: true,
              )
            ],
          )
        ],
        feedbackTips: ['Phát âm rất chuẩn! Tiếp tục duy trì phong độ.'],
      );
    }
  }
}

class MockAudioRecordingService implements AudioRecordingService {
  bool _isRecording = false;
  DateTime? _startTime;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<void> startRecording() async {
    _isRecording = true;
    _startTime = DateTime.now();
  }

  @override
  Future<AudioRecordResult> stopRecording() async {
    _isRecording = false;
    final elapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 5;
    final duration = elapsed < 1 ? 1 : elapsed;
    return AudioRecordResult(
      filePath: '/mock/storage/records/recording_${DateTime.now().millisecondsSinceEpoch}.wav',
      durationSeconds: duration,
    );
  }

  @override
  Future<void> cancelRecording() async {
    _isRecording = false;
    _startTime = null;
  }
}

class MockReminderNotificationService implements ReminderNotificationService {
  bool _scheduled = true;

  @override
  bool get isScheduled => _scheduled;

  @override
  Future<void> scheduleDailyReminder({required String timeString}) async {
    _scheduled = true;
  }

  @override
  Future<void> cancelDailyReminder() async {
    _scheduled = false;
  }
}
