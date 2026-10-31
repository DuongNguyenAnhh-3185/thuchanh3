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
  String _selectedFilter = 'all'; // 'all', 'high', 'mid', 'low'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final user = await _services.authRepo.getCurrentUser();
    final list = await _services.practiceRepo.getHistory(user.id);
    if (!mounted) return;
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  List<PracticeResult> get _filteredHistory {
    switch (_selectedFilter) {
      case 'high':
        return _history.where((s) => (s.scores.overall ?? 0) >= 80).toList();
      case 'mid':
        return _history
            .where((s) => (s.scores.overall ?? 0) >= 60 && (s.scores.overall ?? 0) < 80)
            .toList();
      case 'low':
        return _history.where((s) => (s.scores.overall ?? 0) < 60).toList();
      case 'all':
      default:
        return _history;
    }
  }

  Future<void> _deleteSingleSession(PracticeResult item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lượt luyện tập'),
        content: Text('Bạn có chắc muốn xóa kết quả cho bài "${item.targetText.isNotEmpty ? item.targetText : item.lessonId}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _services.practiceRepo.deleteSession(item.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lượt luyện tập.')),
        );
      }
      await _loadHistory();
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử'),
        content: const Text(
          'Hành động này sẽ xóa vĩnh viễn tất cả kết quả luyện tập của bạn và không thể khôi phục.\nBạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = await _services.authRepo.getCurrentUser();
      await _services.practiceRepo.clearHistory(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toàn bộ lịch sử luyện tập.')),
        );
      }
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Luyện Tập'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Xóa toàn bộ lịch sử',
              onPressed: _clearAllHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: Column(
                children: [
                  _buildSummaryHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: _filteredHistory.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredHistory.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _filteredHistory[index];
                              return _buildHistoryCard(item);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    if (_history.isEmpty) return const SizedBox.shrink();

    final totalSessions = _history.length;
    final totalActiveSeconds = _history.fold<int>(0, (sum, s) => sum + s.activeDurationSeconds);
    final validScores = _history.where((s) => s.scores.overall != null).map((s) => s.scores.overall!).toList();
    final avgScore = validScores.isNotEmpty ? (validScores.reduce((a, b) => a + b) / validScores.length) : 0.0;

    final minutes = totalActiveSeconds ~/ 60;
    final seconds = totalActiveSeconds % 60;
    final timeStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Số lượt', '$totalSessions', Icons.history_rounded, AppTheme.accentIndigo),
          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          _buildStatColumn('Điểm TB', '${avgScore.toStringAsFixed(1)}%', Icons.analytics_outlined, AppTheme.secondaryTeal),
          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          _buildStatColumn('Thời gian', timeStr, Icons.timer_outlined, AppTheme.warningAmber),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildFilterChip('all', 'Tất cả (${_history.length})'),
          const SizedBox(width: 8),
          _buildFilterChip('high', '≥80 Điểm (${_history.where((s) => (s.scores.overall ?? 0) >= 80).length})'),
          const SizedBox(width: 8),
          _buildFilterChip('mid', '60-79 Điểm (${_history.where((s) => (s.scores.overall ?? 0) >= 60 && (s.scores.overall ?? 0) < 80).length})'),
          const SizedBox(width: 8),
          _buildFilterChip('low', '<60 Cần luyện (${_history.where((s) => (s.scores.overall ?? 0) < 60).length})'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = filterKey);
      },
      selectedColor: AppTheme.accentIndigo.withOpacity(0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.accentIndigo : AppTheme.textMuted,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            Text(
              _history.isEmpty
                  ? 'Chưa có lượt luyện tập nào.\nHãy bắt đầu bài luyện đầu tiên!'
                  : 'Không có bài luyện nào khớp với bộ lọc.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
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
            border: Border.all(color: scoreColor.withOpacity(0.35), width: 1.5),
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
                '• ${item.activeDurationSeconds}s ghi âm',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
              tooltip: 'Xóa kết quả này',
              onPressed: () => _deleteSingleSession(item),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
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
