import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _services = AppServices();
  List<UserProfile> _availableUsers = [];
  String? _selectedUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _services.authRepo.getAvailableUsers();
    final current = await _services.authRepo.getCurrentUser();
    setState(() {
      _availableUsers = users;
      _selectedUserId = current.id;
      _isLoading = false;
    });
  }

  Future<void> _handleStart() async {
    if (_selectedUserId != null) {
      await _services.authRepo.switchUser(_selectedUserId!);
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Branding Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accentIndigo, AppTheme.secondaryTeal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentIndigo.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Luyện phát âm chuẩn bản xứ với AI\nVà duy trì kỷ luật học tập mỗi ngày',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // User selection card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn hồ sơ người học (Demo TV1):',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._availableUsers.map((user) {
                                final isSelected = user.id == _selectedUserId;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: isSelected
                                        ? AppTheme.accentIndigo.withOpacity(0.08)
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppTheme.accentIndigo
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: RadioListTile<String>(
                                    value: user.id,
                                    groupValue: _selectedUserId,
                                    activeColor: AppTheme.accentIndigo,
                                    onChanged: (val) {
                                      setState(() => _selectedUserId = val);
                                    },
                                    title: Text(
                                      user.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Cấp độ: ${user.level} • Streak: ${user.streakCount} ngày',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                    ),
                                  ),
                                ),
                              );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start learning button
                      ElevatedButton(
                        onPressed: _handleStart,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bắt đầu học ngay',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info chip about Mock mode
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppTheme.warningAmber),
                            SizedBox(width: 6),
                            Text(
                              'Chế độ Mock dữ liệu sẵn sàng (Không cần API Key)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.warningAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
