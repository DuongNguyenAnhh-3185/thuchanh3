import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_ai_pronunciation/core/routes/app_routes.dart';
import 'package:th3_ai_pronunciation/data/models/practice_result.dart';
import 'package:th3_ai_pronunciation/features/result/result_screen.dart';

Future<PracticeResult> loadMock(String name) async {
  final json = jsonDecode(
    await rootBundle.loadString('assets/mocks/$name'),
  ) as Map<String, dynamic>;
  return PracticeResult.fromJson(json);
}

Future<void> showResult(WidgetTester tester, String mockName) async {
  final result = await loadMock(mockName);
  await tester.pumpWidget(
    MaterialApp(
      home: ResultScreen(args: ResultScreenArgs(result: result)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('high score shows score, metrics, and phoneme comparison', (
    tester,
  ) async {
    await showResult(tester, 'practice_result_high.json');

    expect(find.text('93'), findsOneWidget);
    expect(find.text('Chỉ số chi tiết'), findsOneWidget);
    expect(find.textContaining('Độ chính xác âm vị'), findsOneWidget);
    expect(find.text('think'), findsOneWidget);

    await tester.ensureVisible(find.text('think'));
    await tester.tap(find.text('think'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Phiên âm chuẩn'), findsOneWidget);
    expect(find.textContaining('/θ/'), findsWidgets);
  });

  testWidgets('low score marks pronunciation problems and offers tips', (
    tester,
  ) async {
    await showResult(tester, 'practice_result_low.json');

    expect(find.text('54'), findsOneWidget);
    expect(find.textContaining('Lỗi âm /θ/'), findsNWidgets(2));
    expect(find.text('Luyện lại câu này'), findsOneWidget);

    await tester.ensureVisible(find.text('think'));
    await tester.tap(find.text('think'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn phát âm: /s/'), findsOneWidget);
  });

  testWidgets('missing secondary scores do not render a broken metrics card', (
    tester,
  ) async {
    await showResult(tester, 'practice_result_missing_metrics.json');

    expect(find.text('75'), findsOneWidget);
    expect(find.text('Chỉ số chi tiết'), findsNothing);
    expect(find.text('mother'), findsOneWidget);
  });

  testWidgets('empty recognition result shows a helpful empty state', (
    tester,
  ) async {
    await showResult(tester, 'practice_result_empty.json');

    expect(find.text('--'), findsOneWidget);
    expect(find.textContaining('Không nhận diện được từ nào'), findsOneWidget);
    expect(
      find.textContaining('Không nhận diện được giọng nói'),
      findsOneWidget,
    );
    expect(find.text('Chỉ số chi tiết'), findsNothing);
  });
}
