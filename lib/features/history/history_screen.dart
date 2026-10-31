import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/practice_result.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _services = AppServices();
  List<PracticeResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final user = await _services.authRepo.getCurrentUser();
    final list = await _services.practiceRepo.getHistory(user.id);
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Luyện Tập'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có lượt luyện tập nào.\nHãy bắt đầu bài luyện đầu tiên!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(PracticeResult item) {
    final overall = item.scores.overall;
    final scoreColor = overall == null
        ? AppTheme.textMuted
        : overall >= 80
            ? AppTheme.successGreen
            : overall >= 60
                ? AppTheme.warningAmber
                : AppTheme.errorRed;

    String dateStr = item.completedAt;
    final dt = DateTime.tryParse(item.completedAt)?.toLocal();
    if (dt != null) {
      dateStr = DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: scoreColor.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text(
              overall != null ? overall.toInt().toString() : '--',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scoreColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          item.targetText.isNotEmpty ? item.targetText : 'Bài học ${item.lessonId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${item.activeDurationSeconds}s',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.result,
            arguments: ResultScreenArgs(
              result: item,
              isFromHistory: true,
            ),
          );
        },
      ),
    );
  }
}
