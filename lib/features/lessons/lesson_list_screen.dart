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
  String _selectedLevel = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    final lessons = await _services.lessonRepo.getLessons();
    setState(() {
      _allLessons = lessons;
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
              l.category.toLowerCase().contains(q))
          .toList();
    }
    _filteredLessons = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Bài Luyện Phát Âm'),
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
                      hintText: 'Tìm kiếm bài học, âm vị...',
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
                          ? 'Tất cả'
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
                            return _buildLessonCard(lesson);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    final levelColor = lesson.level == 'Beginner'
        ? AppTheme.secondaryTeal
        : lesson.level == 'Intermediate'
            ? AppTheme.accentIndigo
            : const Color(0xFF7C3AED);

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
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag: Category and Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lesson.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
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

              // Target phonemes chips + CTA arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Âm trọng tâm: ',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
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
