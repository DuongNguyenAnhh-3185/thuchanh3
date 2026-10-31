class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int streakCount;
  final String? lastPracticeDate;
  final int dailyGoalMinutes;
  final String reminderTime;
  final bool isReminderEnabled;
  final String level;
  final int totalSessions;
  final int totalActiveMinutes;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.streakCount,
    this.lastPracticeDate,
    required this.dailyGoalMinutes,
    required this.reminderTime,
    required this.isReminderEnabled,
    required this.level,
    required this.totalSessions,
    required this.totalActiveMinutes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'usr_demo',
      name: json['name'] as String? ?? 'Demo Student',
      email: json['email'] as String? ?? 'student@example.com',
      avatarUrl: json['avatarUrl'] as String?,
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      lastPracticeDate: json['lastPracticeDate'] as String?,
      dailyGoalMinutes: (json['dailyGoalMinutes'] as num?)?.toInt() ?? 5,
      reminderTime: json['reminderTime'] as String? ?? '20:00',
      isReminderEnabled: json['isReminderEnabled'] as bool? ?? true,
      level: json['level'] as String? ?? 'Beginner',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalActiveMinutes: (json['totalActiveMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'streakCount': streakCount,
      'lastPracticeDate': lastPracticeDate,
      'dailyGoalMinutes': dailyGoalMinutes,
      'reminderTime': reminderTime,
      'isReminderEnabled': isReminderEnabled,
      'level': level,
      'totalSessions': totalSessions,
      'totalActiveMinutes': totalActiveMinutes,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    int? streakCount,
    String? lastPracticeDate,
    int? dailyGoalMinutes,
    String? reminderTime,
    bool? isReminderEnabled,
    String? level,
    int? totalSessions,
    int? totalActiveMinutes,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakCount: streakCount ?? this.streakCount,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      level: level ?? this.level,
      totalSessions: totalSessions ?? this.totalSessions,
      totalActiveMinutes: totalActiveMinutes ?? this.totalActiveMinutes,
    );
  }
}
