class DailyProgress {
  final String date; // YYYY-MM-DD
  final int activeSeconds;
  final int targetSeconds;
  final bool isGoalReached;
  final int practiceCount;

  DailyProgress({
    required this.date,
    required this.activeSeconds,
    required this.targetSeconds,
    required this.isGoalReached,
    required this.practiceCount,
  });

  double get progressRatio {
    if (targetSeconds <= 0) return 0.0;
    final ratio = activeSeconds / targetSeconds;
    return ratio.clamp(0.0, 1.0).toDouble();
  }

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: json['date'] as String? ?? '',
      activeSeconds: (json['activeSeconds'] as num?)?.toInt() ?? 0,
      targetSeconds: (json['targetSeconds'] as num?)?.toInt() ?? 300,
      isGoalReached: json['isGoalReached'] as bool? ?? false,
      practiceCount: (json['practiceCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'activeSeconds': activeSeconds,
      'targetSeconds': targetSeconds,
      'isGoalReached': isGoalReached,
      'practiceCount': practiceCount,
    };
  }
}
