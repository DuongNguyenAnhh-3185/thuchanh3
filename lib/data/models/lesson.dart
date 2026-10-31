class Lesson {
  final String id;
  final String title;
  final String level;
  final String category;
  final String text;
  final String ipa;
  final String translationVi;
  final String audioSampleUrl;
  final List<String> targetPhonemes;

  Lesson({
    required this.id,
    required this.title,
    required this.level,
    required this.category,
    required this.text,
    required this.ipa,
    required this.translationVi,
    required this.audioSampleUrl,
    required this.targetPhonemes,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      level: json['level'] as String? ?? 'Beginner',
      category: json['category'] as String? ?? 'General',
      text: json['text'] as String? ?? '',
      ipa: json['ipa'] as String? ?? '',
      translationVi: json['translationVi'] as String? ?? '',
      audioSampleUrl: json['audioSampleUrl'] as String? ?? '',
      targetPhonemes: (json['targetPhonemes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'category': category,
      'text': text,
      'ipa': ipa,
      'translationVi': translationVi,
      'audioSampleUrl': audioSampleUrl,
      'targetPhonemes': targetPhonemes,
    };
  }
}
