import '../models/daily_progress.dart';
import '../models/lesson.dart';
import '../models/practice_result.dart';
import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> getCurrentUser();
  Future<void> updateProfile(UserProfile profile);
  Future<List<UserProfile>> getAvailableUsers();
  Future<void> switchUser(String userId);
}

abstract class LessonRepository {
  Future<List<Lesson>> getLessons();
  Future<Lesson?> getLessonById(String id);
  Future<List<Lesson>> getLessonsByLevel(String level);
}

abstract class PracticeRepository {
  Future<void> savePracticeResult(PracticeResult result);
  Future<PracticeResult?> getSessionResult(String sessionId);
  Future<List<PracticeResult>> getHistory(String userId);
}

abstract class StreakProgressRepository {
  Future<DailyProgress> getTodayProgress(String userId);
  Future<List<DailyProgress>> getWeeklyProgress(String userId);
  Future<void> updateDailyGoal(String userId, int minutes);
  Future<int> recalculateStreak(String userId);
}

abstract class SpeechAiService {
  Future<PracticeResult> evaluatePronunciation({
    required String audioFilePath,
    required String lessonId,
    required String targetText,
    required String expectedIpa,
    required int activeDurationSeconds,
    bool simulateError = false,
    bool simulateLowScore = false,
  });
}

abstract class AudioRecordingService {
  Future<void> startRecording();
  Future<AudioRecordResult> stopRecording();
  Future<void> cancelRecording();
  bool get isRecording;
}

class AudioRecordResult {
  final String filePath;
  final int durationSeconds;

  AudioRecordResult({
    required this.filePath,
    required this.durationSeconds,
  });
}

abstract class ReminderNotificationService {
  Future<void> scheduleDailyReminder({required String timeString});
  Future<void> cancelDailyReminder();
  bool get isScheduled;
}
