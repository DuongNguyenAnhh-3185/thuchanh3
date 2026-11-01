import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/daily_progress.dart';
import '../../data/models/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _services = AppServices();
  UserProfile? _user;
  DailyProgress? _todayProgress;
  List<DailyProgress> _weeklyProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final user = await _services.authRepo.getCurrentUser();
    await _services.streakRepo.recalculateStreak(user.id);
    final updatedUser = await _services.authRepo.getCurrentUser();
    final today = await _services.streakRepo.getTodayProgress(user.id);
    final weekly = await _services.streakRepo.getWeeklyProgress(user.id);

    if (!mounted) return;

    setState(() {
      _user = updatedUser;
      _todayProgress = today;
      _weeklyProgress = weekly;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeMinutes = (_todayProgress?.activeSeconds ?? 0) ~/ 60;
    final activeSecondsRemainder = (_todayProgress?.activeSeconds ?? 0) % 60;
    final goalMinutes = _user!.dailyGoalMinutes;
    final progressRatio = _todayProgress?.progressRatio ?? 0.0;
    final isGoalMet = _todayProgress?.isGoalReached ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${_user!.name} 👋',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Cấp độ: ${_user!.level}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử luyện tập',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.history,
              ).then((_) => _loadDashboardData());
            },
          ),
          IconButton(
            tooltip: 'Cài đặt & Nhắc học',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.settings,
              ).then((_) => _loadDashboardData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. STREAK HERO CARD (Checklist 2 - Đếm số ngày liên tiếp)
              _buildStreakCard(_user!.streakCount, isGoalMet),
              const SizedBox(height: 16),

              // 2. DAILY GOAL PROGRESS CARD (Checklist 2 - Mục tiêu hàng ngày)
              _buildDailyGoalCard(
                activeMinutes: activeMinutes,
                activeSeconds: activeSecondsRemainder,
                goalMinutes: goalMinutes,
                progressRatio: progressRatio,
                isGoalMet: isGoalMet,
              ),
              const SizedBox(height: 16),

              // 3. WEEKLY ACTIVITY CHART (Checklist 2 - Thống kê thời gian học)
              _buildWeeklyStatsCard(_weeklyProgress),
              const SizedBox(height: 20),

              // 4. ACTION BUTTONS (Start practice / View lessons)
              ElevatedButton.icon(
                icon: const Icon(Icons.mic_rounded, size: 22),
                label: const Text(
                  'Luyện phát âm bài mới ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.practice,
                    arguments: PracticeScreenArgs(lessonId: 'les_001'),
                  ).then((_) => _loadDashboardData());
                },
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.library_books_rounded, size: 20),
                label: const Text('Xem toàn bộ danh sách bài học'),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.lessons,
                  ).then((_) => _loadDashboardData());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streakCount, bool isGoalMet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEA580C),
            const Color(0xFFF97316).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Fire icon with circular border
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streakCount',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'NGÀY LIÊN TIẾP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isGoalMet
                      ? 'Tuyệt vời! Bạn đã hoàn thành mục tiêu hôm nay 🎉'
                      : 'Luyện thêm để duy trì ngọn lửa chuỗi ngày của bạn!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard({
    required int activeMinutes,
    required int activeSeconds,
    required int goalMinutes,
    required double progressRatio,
    required bool isGoalMet,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: AppTheme.accentIndigo,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mục tiêu học hôm nay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isGoalMet
                        ? AppTheme.successGreen.withOpacity(0.12)
                        : AppTheme.warningAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isGoalMet ? 'Đạt mục tiêu' : 'Chưa hoàn thành',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isGoalMet
                          ? AppTheme.successGreen
                          : AppTheme.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.textMain),
                    children: [
                      TextSpan(
                        text:
                            '$activeMinutes:${activeSeconds.toString().padLeft(2, '0')} ',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '/ $goalMinutes phút',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progressRatio * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 10,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalMet ? AppTheme.successGreen : AppTheme.accentIndigo,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '* Chỉ tính thời gian luyện tập thực tế, không tính thời gian chờ mạng hay AI.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsCard(List<DailyProgress> weekly) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 20,
                      color: AppTheme.secondaryTeal,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Thống kê 7 ngày qua',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  '(Thời gian học thực tế)',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekly.map((day) {
                final dateParts = day.date.split('-');
                final label = dateParts.length >= 3
                    ? '${dateParts[2]}/${dateParts[1]}'
                    : day.date;
                final minutes = (day.activeSeconds / 60).toStringAsFixed(1);
                final height = (day.progressRatio * 60).clamp(6.0, 60.0);

                return Column(
                  children: [
                    Text(
                      '${minutes}p',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: height,
                      decoration: BoxDecoration(
                        color: day.isGoalReached
                            ? AppTheme.successGreen
                            : (day.activeSeconds > 0
                                  ? AppTheme.accentIndigo.withOpacity(0.6)
                                  : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
