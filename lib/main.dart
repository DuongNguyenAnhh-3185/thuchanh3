import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/history/history_screen.dart';
import 'features/lessons/lesson_list_screen.dart';
import 'features/practice/practice_screen.dart';
import 'features/result/result_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep mock lessons and AI scoring; audio capture uses the device microphone.
  AppServices().initialize(useMock: true);

  runApp(const AiPronunciationApp());
}

class AiPronunciationApp extends StatelessWidget {
  const AiPronunciationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case AppRoutes.dashboard:
            return MaterialPageRoute(builder: (_) => const DashboardScreen());

          case AppRoutes.lessons:
            return MaterialPageRoute(builder: (_) => const LessonListScreen());

          case AppRoutes.practice:
            final args = settings.arguments as PracticeScreenArgs? ??
                PracticeScreenArgs(lessonId: 'les_001');
            return MaterialPageRoute(
              builder: (_) => PracticeScreen(args: args),
            );

          case AppRoutes.result:
            final args = settings.arguments as ResultScreenArgs;
            return MaterialPageRoute(
              builder: (_) => ResultScreen(args: args),
            );

          case AppRoutes.history:
            return MaterialPageRoute(builder: (_) => const HistoryScreen());

          case AppRoutes.settings:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
