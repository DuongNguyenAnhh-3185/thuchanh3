import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/repositories/contracts.dart';

/// Schedules a daily local notification on the device.
class LocalReminderNotificationService implements ReminderNotificationService {
  static const _notificationId = 1001;
  static const _channelId = 'daily_practice_reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final Future<void> _initialized = _initialize();
  bool _isScheduled = false;

  Future<void> _initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  bool get isScheduled => _isScheduled;

  @override
  Future<void> scheduleDailyReminder({required String timeString}) async {
    await _initialized;
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(timeString);
    final hour = int.tryParse(match?.group(1) ?? '');
    final minute = int.tryParse(match?.group(2) ?? '');
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      throw FormatException('Invalid reminder time: $timeString');
    }

    await _requestPermissions();
    await _plugin.cancel(id: _notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Nhắc học hàng ngày',
        channelDescription: 'Nhắc luyện phát âm tiếng Anh mỗi ngày',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Đến giờ luyện phát âm rồi! 🔥',
      body: 'Duy trì Streak bằng một phiên luyện tập ngắn hôm nay nhé.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    _isScheduled = true;
  }

  @override
  Future<void> cancelDailyReminder() async {
    await _initialized;
    await _plugin.cancel(id: _notificationId);
    _isScheduled = false;
  }
}
