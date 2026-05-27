import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_enum.dart';

class NotificationService {
  NotificationService._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(init);
    _ready = true;
  }

  static Future<void> requestPermissions() async {
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a daily reminder for each prayer at a default approximate time.
  /// In a fuller build this would use real prayer times from a city.
  static Future<void> scheduleDailyReminders() async {
    await init();
    await _plugin.cancelAll();
    final defaults = {
      Prayer.fajr: const (h: 5, m: 30),
      Prayer.dhuhr: const (h: 13, m: 0),
      Prayer.asr: const (h: 16, m: 30),
      Prayer.maghrib: const (h: 19, m: 0),
      Prayer.isha: const (h: 20, m: 30),
    };
    int id = 1;
    for (final entry in defaults.entries) {
      final t = entry.value;
      final next = _nextInstanceOf(t.h, t.m);
      await _plugin.zonedSchedule(
        id++,
        '${entry.key.name} time',
        'Time to pray ${entry.key.name}',
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
              'prayer_reminders', 'Prayer reminders',
              importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
