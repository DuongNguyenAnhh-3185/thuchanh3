import '../../data/repositories/contracts.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/services/device_audio_recording_service.dart';
import '../../data/repositories/sqlite_repositories.dart';

class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;
  AppServices._internal();

  bool isMockMode = false; // Default to real SQLite persistence

  late AuthRepository authRepo;
  late LessonRepository lessonRepo;
  late PracticeRepository practiceRepo;
  late StreakProgressRepository streakRepo;
  late SpeechAiService speechAiService;
  late AudioRecordingService audioRecordingService;
  late ReminderNotificationService reminderService;

  void initialize({bool useMock = false}) {
    isMockMode = useMock;

    if (useMock) {
      authRepo = MockAuthRepository();
      lessonRepo = MockLessonRepository();
      practiceRepo = MockPracticeRepository();
      streakRepo = MockStreakProgressRepository(
        practiceRepo: practiceRepo,
        authRepo: authRepo,
      );
    } else {
      authRepo = SqliteAuthRepository();
      lessonRepo = SqliteLessonRepository();
      practiceRepo = SqlitePracticeRepository();
      streakRepo = SqliteStreakProgressRepository(
        practiceRepo: practiceRepo,
        authRepo: authRepo,
      );
    }

    speechAiService = MockSpeechAiService();
    // Keep mock pronunciation scoring, but capture real audio from the device.
    audioRecordingService = DeviceAudioRecordingService();
    reminderService = MockReminderNotificationService();
  }
}
