import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/practice_result.dart';

class ResultScreen extends StatelessWidget {
  final ResultScreenArgs args;

  const ResultScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final result = args.result;
    final overall = result.scores.overall;

    final scoreColor = overall == null
        ? AppTheme.textMuted
        : overall >= 80
            ? AppTheme.successGreen
            : overall >= 60
                ? AppTheme.warningAmber
                : AppTheme.errorRed;

    final scoreTitle = overall == null
        ? 'Chưa tính được điểm'
        : overall >= 80
            ? 'Phát âm Tuyệt vời! 🌟'
            : overall >= 60
                ? 'Khá tốt! Cần chú ý vài âm 🎯'
                : 'Cần luyện tập thêm 💪';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Đánh Giá Phát Âm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(
              context,
              ModalRoute.withName(AppRoutes.dashboard),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. OVERALL SCORE CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    // Circular score gauge
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scoreColor, width: 6),
                        color: scoreColor.withOpacity(0.08),
                      ),
                      child: Center(
                        child: Text(
                          overall != null ? overall.toStringAsFixed(0) : '--',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      scoreTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thời gian luyện tập thực tế: ${result.activeDurationSeconds} giây',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. SUB-METRICS BREAKDOWN (Handles null safety safely)
            if (result.scores.accuracy != null ||
                result.scores.fluency != null ||
                result.scores.completeness != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉ số chi tiết',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (result.scores.accuracy != null)
                        _buildMetricRow('Độ chính xác âm vị (Accuracy)', result.scores.accuracy!),
                      if (result.scores.fluency != null)
                        _buildMetricRow('Độ lưu loát & Nhịp điệu (Fluency)', result.scores.fluency!),
                      if (result.scores.completeness != null)
                        _buildMetricRow('Độ hoàn chỉnh câu (Completeness)', result.scores.completeness!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. INTERACTIVE WORD-BY-WORD PHONEME ANALYSIS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chi tiết từng từ (Chạm để xem âm vị)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Icon(Icons.touch_app_outlined, size: 18, color: AppTheme.accentIndigo),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Màu xanh: Chuẩn • Màu vàng: Cần sửa • Màu đỏ: Sai âm vị',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 14),

                    // Word chips
                    if (result.words.isEmpty)
                      const Text(
                        'Không nhận diện được từ nào trong bản ghi.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.words.map((wordEval) {
                          final color = wordEval.status == 'correct'
                              ? AppTheme.successGreen
                              : wordEval.status == 'warning'
                                  ? AppTheme.warningAmber
                                  : AppTheme.errorRed;

                          return ActionChip(
                            backgroundColor: color.withOpacity(0.12),
                            side: BorderSide(color: color, width: 1.5),
                            label: Text(
                              wordEval.word,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            onPressed: () => _showPhonemeDetails(context, wordEval),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. AI FEEDBACK & SUGGESTIONS
            if (result.feedbackTips.isNotEmpty) ...[
              Card(
                color: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: AppTheme.successGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gợi ý cải thiện từ AI',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...result.feedbackTips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF166534), height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. ACTION BUTTONS (Retry / Home)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Luyện lại câu này'),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.practice,
                        arguments: PracticeScreenArgs(lessonId: result.lessonId),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Về Trang chủ'),
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName(AppRoutes.dashboard),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              Text(
                '${score.toInt()}/100',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 80
                    ? AppTheme.successGreen
                    : score >= 60
                        ? AppTheme.warningAmber
                        : AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhonemeDetails(BuildContext context, WordEvaluation wordEval) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích từ: "${wordEval.word}"',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Phiên âm chuẩn: ${wordEval.ipa}',
                        style: const TextStyle(fontSize: 14, color: AppTheme.accentIndigo, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (wordEval.score >= 80
                              ? AppTheme.successGreen
                              : wordEval.score >= 60
                                  ? AppTheme.warningAmber
                                  : AppTheme.errorRed)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${wordEval.score.toInt()} đ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: wordEval.score >= 80
                            ? AppTheme.successGreen
                            : wordEval.score >= 60
                                ? AppTheme.warningAmber
                                : AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Chi tiết từng âm vị (Phoneme comparison):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (wordEval.phonemes.isEmpty)
                const Text(
                  'Không có phân tích âm vị cấp chi tiết cho từ này.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                )
              else
                ...wordEval.phonemes.map((ph) {
                  final isRight = ph.isCorrect;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRight
                          ? AppTheme.successGreen.withOpacity(0.08)
                          : AppTheme.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isRight
                            ? AppTheme.successGreen.withOpacity(0.3)
                            : AppTheme.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isRight ? Icons.check_circle : Icons.cancel,
                              color: isRight ? AppTheme.successGreen : AppTheme.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Âm chuẩn: /${ph.ipaExpected}/',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          isRight ? 'Chính xác' : 'Bạn phát âm: /${ph.ipaActual}/',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isRight ? AppTheme.successGreen : AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
