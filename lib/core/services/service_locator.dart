import '../../data/repositories/contracts.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/services/device_audio_recording_service.dart';

class AppServices {
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;
  AppServices._internal();

  bool isMockMode = true;

  late AuthRepository authRepo;
  late LessonRepository lessonRepo;
  late PracticeRepository practiceRepo;
  late StreakProgressRepository streakRepo;
  late SpeechAiService speechAiService;
  late AudioRecordingService audioRecordingService;
  late ReminderNotificationService reminderService;

  void initialize({bool useMock = true}) {
    isMockMode = useMock;
    authRepo = MockAuthRepository();
    lessonRepo = MockLessonRepository();
    practiceRepo = MockPracticeRepository();
    streakRepo = MockStreakProgressRepository(
      practiceRepo: practiceRepo,
      authRepo: authRepo,
    );
    speechAiService = MockSpeechAiService();
    // Keep mock pronunciation scoring, but capture real audio from the device.
    audioRecordingService = DeviceAudioRecordingService();
    reminderService = MockReminderNotificationService();
  }
}
