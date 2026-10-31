class AppConstants {
  static const String appName = 'AI Pronunciation Coach';
  static const String appVersion = '1.0.0 (TH3)';

  // Default values
  static const int defaultDailyGoalMinutes = 5;
  static const String defaultReminderTime = '20:00';
  static const String defaultLocale = 'en-US';

  // Level names
  static const String levelBeginner = 'Beginner';
  static const String levelIntermediate = 'Intermediate';
  static const String levelAdvanced = 'Advanced';

  // Statuses
  static const String statusProcessing = 'processing';
  static const String statusCompleted = 'completed';
  static const String statusFailed = 'failed';

  // Word status
  static const String wordCorrect = 'correct';
  static const String wordWarning = 'warning';
  static const String wordIncorrect = 'incorrect';

  // Asset paths
  static const String mockLessonsPath = 'assets/mocks/lessons.json';
  static const String mockResultHighPath = 'assets/mocks/practice_result_high.json';
  static const String mockResultLowPath = 'assets/mocks/practice_result_low.json';
  static const String mockResultMissingPath = 'assets/mocks/practice_result_missing_metrics.json';
  static const String mockResultEmptyPath = 'assets/mocks/practice_result_empty.json';
  static const String mockHistoryMultiPath = 'assets/mocks/history_multi_days.json';
  static const String mockHistoryGapsPath = 'assets/mocks/history_with_gaps.json';
  static const String mockUserProfilePath = 'assets/mocks/user_profile.json';
}
