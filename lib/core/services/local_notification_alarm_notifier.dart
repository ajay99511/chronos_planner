import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chronosky/core/services/alarm_notifier.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/todo_item_model.dart';

/// Schedules alarms through `flutter_local_notifications`.
///
/// Thin by design: every decision about *which* alarms to schedule and what
/// identity they get lives in `alarm_notifier.dart` and is unit-tested. What is
/// left here is platform wiring, which needs a device to verify — see
/// docs/decisions/0010.
class LocalNotificationAlarmNotifier implements AlarmNotifier {
  LocalNotificationAlarmNotifier(
    this._logger, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialised = false;

  /// Dedicated channel so a user can silence reminders without silencing
  /// alarms, and so the system treats these with alarm priority.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chronos_alarms',
    'Alarms',
    description: 'Scheduled alarms you set in Chronos.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  @override
  Future<void> initialise() async {
    if (_initialised) return;

    // zonedSchedule needs a real IANA zone. Without it tz.local is UTC and
    // every alarm fires at the wrong wall-clock time; a fixed offset would be
    // wrong twice a year instead, which is worse because it looks correct.
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e, stackTrace) {
      // Leaves tz.local as UTC. Logged loudly because alarms will be offset,
      // which is a correctness failure rather than a cosmetic one.
      _logger.error('Could not resolve the device timezone', e, stackTrace);
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open Chronos'),
        windows: WindowsInitializationSettings(
          appName: 'Chronos',
          appUserModelId: 'com.example.chronos_planner',
          guid: 'd4f7a1e2-8c3b-4a59-9f2d-6b1e7c0a5d38',
        ),
      ),
    );

    await _android?.createNotificationChannel(_channel);
    _initialised = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final android = _android;
    if (android == null) return true; // Desktop and iOS need no equivalent.
    return await android.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android == null) return hasPermission();

    // Two separate grants on modern Android: delivery, and the right to be
    // exact. An inexact alarm can be deferred by Doze for minutes or longer,
    // which is useless for an alarm clock.
    final granted = await android.requestNotificationsPermission() ?? false;
    try {
      await android.requestExactAlarmsPermission();
    } catch (e) {
      // Not fatal: on API 33+ USE_EXACT_ALARM is granted at install, so this
      // call is only meaningful on 31-32.
      _logger.warning('Exact-alarm permission request failed: $e');
    }
    return granted;
  }

  @override
  Future<void> sync(List<TodoItem> alarms) async {
    await initialise();
    await cancelAll();

    final due = schedulableAlarms(alarms, DateTime.now());
    for (final alarm in due) {
      try {
        await _plugin.zonedSchedule(
          id: notificationIdFor(alarm.id),
          title: alarm.title,
          body: alarm.description.isEmpty ? 'Alarm' : alarm.description,
          scheduledDate: tz.TZDateTime.from(alarm.scheduledAt!, tz.local),
          // exactAllowWhileIdle is the point of the exercise: anything else is
          // subject to Doze batching.
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: alarm.id,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.alarm,
              // Survives a swipe: an alarm the user can brush away by accident
              // is not an alarm.
              ongoing: true,
              autoCancel: false,
            ),
            iOS: const DarwinNotificationDetails(
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
            macOS: const DarwinNotificationDetails(),
          ),
        );
      } catch (e, stackTrace) {
        // One bad alarm must not stop the rest from being scheduled.
        _logger.error('Could not schedule alarm ${alarm.id}', e, stackTrace);
      }
    }
    _logger.info('Scheduled ${due.length} alarm(s) with the OS');
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e, stackTrace) {
      _logger.error('Could not clear scheduled alarms', e, stackTrace);
    }
  }
}
