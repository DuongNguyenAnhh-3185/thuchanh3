import 'package:flutter_test/flutter_test.dart';
import 'package:th3_ai_pronunciation/core/services/service_locator.dart';
import 'package:th3_ai_pronunciation/main.dart';

void main() {
  testWidgets('App launches and displays LoginScreen branding', (WidgetTester tester) async {
    AppServices().initialize(useMock: true);

    await tester.pumpWidget(const AiPronunciationApp());
    await tester.pumpAndSettle();

    expect(find.text('AI Pronunciation Coach'), findsOneWidget);
    expect(find.text('Bắt đầu học ngay'), findsOneWidget);
  });
}
