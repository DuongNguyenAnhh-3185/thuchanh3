import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final _services = AppServices();
  List<Lesson> _allLessons = [];
  List<Lesson> _filteredLessons = [];
  Map<String, double> _bestScoresByLesson = {};
  String _selectedLevel = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessonsAndProgress();
  }

  Future<void> _loadLessonsAndProgress() async {
    setState(() => _isLoading = true);
    final user = await _services.authRepo.getCurrentUser();
    final lessons = await _services.lessonRepo.getLessons();
    final history = await _services.practiceRepo.getHistory(user.id);

    // Compute best score per lesson
    final Map<String, double> bestScores = {};
    for (final session in history) {
      final overall = session.scores.overall;
      if (overall != null) {
        if (!bestScores.containsKey(session.lessonId) || overall > bestScores[session.lessonId]!) {
          bestScores[session.lessonId] = overall;
        }
      }
    }

    setState(() {
      _allLessons = lessons;
      _bestScoresByLesson = bestScores;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    var result = _allLessons;
    if (_selectedLevel != 'All') {
      result = result
          .where((l) => l.level.toLowerCase() == _selectedLevel.toLowerCase())
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.text.toLowerCase().contains(q) ||
              l.category.toLowerCase().contains(q) ||
              l.targetPhonemes.any((p) => p.toLowerCase().contains(q)))
          .toList();
    }
    _filteredLessons = result;
  }

  void _playQuickSample(Lesson lesson) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Phát âm mẫu: "${lesson.text}"', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Bài Luyện Phát Âm'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLessonsAndProgress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bài học, âm vị /θ/, /ð/...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _applyFilter();
                      });
                    },
                  ),
                ),

                // Level Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: ['All', 'Beginner', 'Intermediate', 'Advanced'].map((level) {
                      final isSelected = _selectedLevel == level;
                      final label = level == 'All'
                          ? 'Tất cả (${_allLessons.length})'
                          : level == 'Beginner'
                              ? 'Cơ bản'
                              : level == 'Intermediate'
                                  ? 'Trung cấp'
                                  : 'Nâng cao';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppTheme.accentIndigo,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMain,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedLevel = level;
                                _applyFilter();
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // List of Lessons
                Expanded(
                  child: _filteredLessons.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy bài học phù hợp.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredLessons.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final lesson = _filteredLessons[index];
                            final bestScore = _bestScoresByLesson[lesson.id];
                            return _buildLessonCard(lesson, bestScore);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, double? bestScore) {
    final levelColor = lesson.level == 'Beginner'
        ? AppTheme.secondaryTeal
        : lesson.level == 'Intermediate'
            ? AppTheme.accentIndigo
            : const Color(0xFF7C3AED);

    final isCompleted = bestScore != null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.practice,
            arguments: PracticeScreenArgs(
              lessonId: lesson.id,
              initialLesson: lesson,
            ),
          ).then((_) => _loadLessonsAndProgress());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag: Category and Level + Completion Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lesson.level,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: levelColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lesson.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Điểm cao nhất: ${bestScore.toInt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),

              // Target sentence
              Text(
                '"${lesson.text}"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.accentIndigo,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),

              // IPA
              Text(
                lesson.ipa,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),

              // Target phonemes chips + Audio Sample Button + CTA arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ...lesson.targetPhonemes.map(
                        (p) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '/$p/',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.warningAmber,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Nghe nhanh âm mẫu',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.volume_up_outlined, size: 18, color: AppTheme.accentIndigo),
                        onPressed: () => _playQuickSample(lesson),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Luyện đọc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentIndigo,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: AppTheme.accentIndigo),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
