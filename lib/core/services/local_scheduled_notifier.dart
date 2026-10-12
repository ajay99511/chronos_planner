import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/services/scheduled_notification.dart';
import 'package:chronosky/core/services/scheduled_notifier.dart';

/// Schedules notifications through `flutter_local_notifications`.
///
/// Thin by design: every decision about *which* notifications to schedule and
/// what identity they get lives in `scheduled_notification.dart` and
/// `task_reminders.dart` and is unit-tested. What is left here is platform
/// wiring, which needs a device to verify — see docs/decisions/0010.
///
/// Delivery also depends on two receivers being declared in
/// `android/app/src/main/AndroidManifest.xml`. Without them the OS fires the
/// broadcast and nothing listens, so nothing is ever shown — a failure no test
/// in this repo can see. See docs/TASK_REMINDERS_DESIGN.md §2.
class LocalScheduledNotifier implements ScheduledNotifier {
  LocalScheduledNotifier(
    this._logger, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialised = false;

  /// Alarms: maximum importance, and the system treats them as alarm-category.
  static const AndroidNotificationChannel _alarmChannel =
      AndroidNotificationChannel(
    'chronos_alarms',
    'Alarms',
    description: 'Scheduled alarms you set in Chronos.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Reminders: a separate channel, deliberately.
  ///
  /// Android's per-channel settings are the user's control surface, so this is
  /// what lets someone mute task nudges while keeping alarms loud. One shared
  /// channel would take that choice away.
  static const AndroidNotificationChannel _reminderChannel =
      AndroidNotificationChannel(
    'chronos_reminders',
    'Task reminders',
    description: 'Nudges before a scheduled task starts.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static AndroidNotificationChannel _channelFor(
    ScheduledNotificationKind kind,
  ) =>
      switch (kind) {
        ScheduledNotificationKind.alarm => _alarmChannel,
        ScheduledNotificationKind.reminder => _reminderChannel,
      };

  @override
  Future<void> initialise() async {
    if (_initialised) return;

    // zonedSchedule needs a real IANA zone. Without it tz.local is UTC and
    // every notification fires at the wrong wall-clock time; a fixed offset
    // would be wrong twice a year instead, which is worse because it looks
    // correct.
    tz_data.initializeTimeZones();
    await _resolveLocalZone();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open Chronos'),
        windows: WindowsInitializationSettings(
          appName: 'Chronos',
          appUserModelId: 'io.github.ajay99511.chronos_planner',
          guid: 'd4f7a1e2-8c3b-4a59-9f2d-6b1e7c0a5d38',
        ),
      ),
    );

    final android = _android;
    if (android != null) {
      await android.createNotificationChannel(_alarmChannel);
      await android.createNotificationChannel(_reminderChannel);
    }
    _initialised = true;
  }

  /// Re-reads the device timezone and points `tz.local` at it.
  ///
  /// Called on every [sync] rather than once at startup: a user who flies
  /// across zones keeps the same process alive, and a reminder resolved
  /// against the old zone fires at the wrong local time with nothing to
  /// indicate why.
  Future<void> _resolveLocalZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e, stackTrace) {
      // Leaves tz.local as whatever it was (UTC on a first failure). Logged
      // loudly because notifications will be offset, which is a correctness
      // failure rather than a cosmetic one.
      _logger.error('Could not resolve the device timezone', e, stackTrace);
    }
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
    // which is useless for an alarm clock and not much better for a reminder
    // whose whole value is arriving before the task starts.
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
  Future<void> sync(List<ScheduledNotification> items) async {
    await initialise();
    // The zone can change without the process restarting, and a stale zone
    // silently offsets everything scheduled below.
    await _resolveLocalZone();
    await cancelAll();

    var scheduled = 0;
    for (final item in items) {
      try {
        await _plugin.zonedSchedule(
          id: item.notificationId,
          title: item.title,
          body: item.body,
          scheduledDate: tz.TZDateTime.from(item.fireAt, tz.local),
          // exactAllowWhileIdle is the point of the exercise: anything else is
          // subject to Doze batching.
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '${item.kind.name}:${item.ownerId}',
          notificationDetails: _detailsFor(item),
        );
        scheduled++;
      } catch (e, stackTrace) {
        // One bad item must not stop the rest from being scheduled.
        _logger.error(
          'Could not schedule ${item.kind.name} ${item.ownerId}',
          e,
          stackTrace,
        );
      }
    }
    _logger.info('Scheduled $scheduled notification(s) with the OS');
  }

  NotificationDetails _detailsFor(ScheduledNotification item) {
    final channel = _channelFor(item.kind);
    final isAlarm = item.kind == ScheduledNotificationKind.alarm;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: isAlarm ? Priority.high : Priority.defaultPriority,
        category: isAlarm
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        // An alarm the user can brush away by accident is not an alarm. A
        // reminder that cannot be brushed away is an annoyance, so the two
        // differ here on purpose.
        ongoing: isAlarm,
        autoCancel: !isAlarm,
      ),
      // timeSensitive for both, not `critical` for alarms: critical needs an
      // Apple entitlement this app does not hold, and requesting a level that
      // is refused is worse than the level below it.
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: const DarwinNotificationDetails(),
    );
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e, stackTrace) {
      _logger.error('Could not clear scheduled notifications', e, stackTrace);
    }
  }
}
