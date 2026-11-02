import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/app_constants.dart';
import '../models/lesson.dart';
import '../models/user_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Cross-platform FFI initialization for Desktop (Windows/Linux)
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'th3_ai_pronunciation.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Table users (Checklist 1)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        avatar_url TEXT,
        streak_count INTEGER NOT NULL DEFAULT 0,
        last_practice_date TEXT,
        daily_goal_minutes INTEGER NOT NULL DEFAULT 5,
        reminder_time TEXT NOT NULL DEFAULT '20:00',
        is_reminder_enabled INTEGER NOT NULL DEFAULT 1,
        level TEXT NOT NULL DEFAULT 'Beginner',
        total_sessions INTEGER NOT NULL DEFAULT 0,
        total_active_minutes INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Table lessons
    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        level TEXT NOT NULL,
        category TEXT NOT NULL,
        text TEXT NOT NULL,
        ipa TEXT NOT NULL,
        translation_vi TEXT NOT NULL,
        audio_sample_url TEXT NOT NULL,
        target_phonemes TEXT NOT NULL
      )
    ''');

    // 3. Table practice_sessions (Checklist 1)
    await db.execute('''
      CREATE TABLE practice_sessions (
        session_id TEXT PRIMARY KEY,
        lesson_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        active_duration_seconds INTEGER NOT NULL,
        status TEXT NOT NULL,
        overall_score REAL,
        accuracy_score REAL,
        fluency_score REAL,
        completeness_score REAL,
        transcript TEXT,
        target_text TEXT NOT NULL,
        words_json TEXT NOT NULL,
        feedback_tips_json TEXT NOT NULL,
        FOREIGN KEY(lesson_id) REFERENCES lessons(id),
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // 4. Table daily_progress
    await db.execute('''
      CREATE TABLE daily_progress (
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        active_seconds INTEGER NOT NULL DEFAULT 0,
        target_seconds INTEGER NOT NULL DEFAULT 300,
        is_goal_reached INTEGER NOT NULL DEFAULT 0,
        practice_count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(user_id, date),
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // Seed initial data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed Team Lead profile and sample student
    final leadUser = UserProfile(
      id: 'usr_nguyen_anh',
      name: 'Nguyên Anh (Nhóm trưởng)',
      email: 'nguyenanh@example.com',
      streakCount: 5,
      dailyGoalMinutes: 5,
      reminderTime: '20:00',
      isReminderEnabled: true,
      level: 'Intermediate',
      totalSessions: 12,
      totalActiveMinutes: 64,
    );

    final memberDemo = UserProfile(
      id: 'usr_student_02',
      name: 'Học viên Demo',
      email: 'hocvien@example.com',
      streakCount: 1,
      dailyGoalMinutes: 3,
      reminderTime: '19:30',
      isReminderEnabled: true,
      level: 'Beginner',
      totalSessions: 3,
      totalActiveMinutes: 10,
    );

    await db.insert('users', _userToMap(leadUser));
    await db.insert('users', _userToMap(memberDemo));

    // Seed lessons from mock assets
    try {
      final jsonString = await rootBundle.loadString(AppConstants.mockLessonsPath);
      final List<dynamic> list = json.decode(jsonString);
      for (final item in list) {
        final lesson = Lesson.fromJson(item as Map<String, dynamic>);
        await db.insert('lessons', {
          'id': lesson.id,
          'title': lesson.title,
          'level': lesson.level,
          'category': lesson.category,
          'text': lesson.text,
          'ipa': lesson.ipa,
          'translation_vi': lesson.translationVi,
          'audio_sample_url': lesson.audioSampleUrl,
          'target_phonemes': json.encode(lesson.targetPhonemes),
        });
      }
    } catch (_) {
      // Fallback default lesson
      await db.insert('lessons', {
        'id': 'les_001',
        'title': 'Voiceless TH /θ/ - Think & Thought',
        'level': 'Beginner',
        'category': 'Consonants',
        'text': 'I think this is the right path.',
        'ipa': '/aɪ θɪŋk ðɪs ɪz ðə raɪt pæθ/',
        'translation_vi': 'Tôi nghĩ đây là con đường đúng đắn.',
        'audio_sample_url': 'assets/audio/les_001.mp3',
        'target_phonemes': json.encode(['θ', 'ð', 'p']),
      });
    }

    // Seed initial practice history
    try {
      final jsonHistory = await rootBundle.loadString(AppConstants.mockHistoryMultiPath);
      final List<dynamic> historyList = json.decode(jsonHistory);
      for (final item in historyList) {
        final map = item as Map<String, dynamic>;
        await db.insert('practice_sessions', {
          'session_id': map['sessionId'] ?? 'sess_${DateTime.now().millisecondsSinceEpoch}',
          'lesson_id': map['lessonId'] ?? 'les_001',
          'user_id': 'usr_nguyen_anh',
          'completed_at': map['completedAt'] ?? DateTime.now().toUtc().toIso8601String(),
          'active_duration_seconds': map['activeDurationSeconds'] ?? 300,
          'status': map['status'] ?? 'completed',
          'overall_score': (map['scores']?['overall'] as num?)?.toDouble() ?? 85.0,
          'accuracy_score': (map['scores']?['accuracy'] as num?)?.toDouble() ?? 85.0,
          'fluency_score': (map['scores']?['fluency'] as num?)?.toDouble() ?? 85.0,
          'completeness_score': (map['scores']?['completeness'] as num?)?.toDouble() ?? 90.0,
          'transcript': map['transcript'] ?? '',
          'target_text': map['targetText'] ?? '',
          'words_json': json.encode(map['words'] ?? []),
          'feedback_tips_json': json.encode(map['feedbackTips'] ?? ['Phát âm rất tốt!']),
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic> _userToMap(UserProfile user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'avatar_url': user.avatarUrl,
      'streak_count': user.streakCount,
      'last_practice_date': user.lastPracticeDate,
      'daily_goal_minutes': user.dailyGoalMinutes,
      'reminder_time': user.reminderTime,
      'is_reminder_enabled': user.isReminderEnabled ? 1 : 0,
      'level': user.level,
      'total_sessions': user.totalSessions,
      'total_active_minutes': user.totalActiveMinutes,
    };
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
