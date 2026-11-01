import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _services = AppServices();
  UserProfile? _user;
  bool _isLoading = true;

  int _selectedGoal = 5;
  String _reminderTime = '20:00';
  bool _isReminderEnabled = true;
  bool _isMockMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = await _services.authRepo.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _selectedGoal = user.dailyGoalMinutes;
      _reminderTime = user.reminderTime;
      _isReminderEnabled = user.isReminderEnabled;
      _isMockMode = _services.isMockMode;
      _isLoading = false;
    });

    if (_isReminderEnabled) {
      try {
        await _services.reminderService.scheduleDailyReminder(
          timeString: _reminderTime,
        );
      } catch (_) {}
    } else {
      try {
        await _services.reminderService.cancelDailyReminder();
      } catch (_) {}
    }
  }

  Future<void> _saveSettings() async {
    if (_user == null) return;
    if (_selectedGoal <= 0 || !_isValidReminderTime(_reminderTime)) {
      _showError('Vui lòng chọn mục tiêu và thời gian nhắc hợp lệ.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updated = _user!.copyWith(
        dailyGoalMinutes: _selectedGoal,
        reminderTime: _reminderTime,
        isReminderEnabled: _isReminderEnabled,
      );
      await _services.authRepo.updateProfile(updated);
      await _services.streakRepo.updateDailyGoal(_user!.id, _selectedGoal);

      if (_isReminderEnabled) {
        await _services.reminderService.scheduleDailyReminder(
          timeString: _reminderTime,
        );
      } else {
        await _services.reminderService.cancelDailyReminder();
      }

      _services.isMockMode = _isMockMode;

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình học tập và thông báo thành công!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(
        'Đã lưu cài đặt nhưng chưa lên lịch được thông báo. '
        'Hãy kiểm tra quyền thông báo trên thiết bị.',
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final initialHour =
        (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 20;
    final initialMinute =
        (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour < 0 ? 0 : (initialHour > 23 ? 23 : initialHour),
        minute: initialMinute < 0
            ? 0
            : (initialMinute > 59 ? 59 : initialMinute),
      ),
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _reminderTime = '$hourStr:$minuteStr';
      });
    }
  }

  bool _isValidReminderTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt & Nhắc Học')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DAILY GOAL SETTING (Checklist 2)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          color: AppTheme.accentIndigo,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mục tiêu luyện tập mỗi ngày',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hoàn thành đủ thời gian này mỗi ngày để tích lũy chuỗi Streak 🔥',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [3, 5, 10, 15].map((mins) {
                        final isSelected = _selectedGoal == mins;
                        return ChoiceChip(
                          label: Text('$mins phút'),
                          selected: isSelected,
                          selectedColor: AppTheme.accentIndigo,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textMain,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedGoal = mins);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. DAILY REMINDER NOTIFICATIONS (Checklist 6)
            Card(
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
                              Icons.notifications_active_rounded,
                              color: AppTheme.secondaryTeal,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Nhắc nhở học tập hàng ngày',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isReminderEnabled,
                          activeColor: AppTheme.secondaryTeal,
                          onChanged: (val) {
                            setState(() => _isReminderEnabled = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hệ thống sẽ gửi thông báo đẩy để nhắc bạn luyện phát âm và bảo vệ chuỗi Streak.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    if (_isReminderEnabled) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Giờ gửi thông báo:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _reminderTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: _pickReminderTime,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. ENGINE MODE TOGGLE (Mock vs Real AI)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: AppTheme.warningAmber,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cấu hình Dịch vụ AI & Dữ liệu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Chế độ Mock Dữ liệu mẫu (Khuyên dùng)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Chạy mượt mà offline với kho bài học và bộ kết quả âm vị mẫu.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      value: _isMockMode,
                      activeColor: AppTheme.warningAmber,
                      onChanged: (val) {
                        setState(() => _isMockMode = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Lưu Cài Đặt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
