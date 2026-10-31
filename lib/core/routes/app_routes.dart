import '../../data/models/lesson.dart';
import '../../data/models/practice_result.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String lessons = '/lessons';
  static const String practice = '/practice';
  static const String result = '/result';
  static const String history = '/history';
  static const String settings = '/settings';
}

/// Arguments passed to PracticeScreen (/practice)
class PracticeScreenArgs {
  final String lessonId;
  final Lesson? initialLesson;

  PracticeScreenArgs({
    required this.lessonId,
    this.initialLesson,
  });
}

/// Arguments passed to ResultScreen (/result)
class ResultScreenArgs {
  final PracticeResult result;
  final bool isFromHistory;

  ResultScreenArgs({
    required this.result,
    this.isFromHistory = false,
  });
}
