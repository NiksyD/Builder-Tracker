import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/account.dart';
import '../models/upgrade.dart';

/// Schedules two alerts per upgrade: a heads-up before it finishes and a
/// "builder free" alert at the end. Scheduled with the OS, so they fire even
/// when the app is closed.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Minutes before completion for the heads-up alert.
  Duration leadTime = const Duration(minutes: 10);

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (!_supported) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    if (await android?.canScheduleExactNotifications() == false) {
      await android?.requestExactAlarmsPermission();
    }
    _ready = true;
  }

  // Two stable ids per upgrade derived from its string id.
  int _id(String upgradeId, int slot) => (upgradeId.hashCode & 0x3FFFFFFF) * 2 % 0x7FFFFFFF + slot;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'builders',
      'Builder alerts',
      channelDescription: 'Tells you when a builder is about to be free',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Cancels everything and reschedules from [upgrades]. Cheap enough to call
  /// after every change.
  Future<void> sync(List<Account> accounts) async {
    if (!_ready) return;
    await _plugin.cancelAllPendingNotifications();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = DateTime.now();

    Future<void> schedule(int id, DateTime at, String title, String body) async {
      if (!at.isAfter(now)) return;
      await _plugin.zonedSchedule(
        id: id,
        // UTC instant: correct regardless of the device's local zone.
        scheduledDate: tz.TZDateTime.from(at, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: mode,
        title: title,
        body: body,
      );
    }

    final multi = accounts.length > 1;
    for (final a in accounts) {
      for (final u in a.upgrades) {
        final v = u.village == Village.home ? 'Home Village' : 'Builder Base';
        final where = multi ? '${a.name} · $v' : v;
        final key = '${a.id}:${u.id}';
        if (u.endsAt.difference(now) > leadTime) {
          await schedule(_id(key, 0), u.endsAt.subtract(leadTime), 'Almost ready · $where',
              '${u.name} finishes in ${leadTime.inMinutes} minutes.');
        }
        await schedule(_id(key, 1), u.endsAt, u.lab ? 'Lab free! · $where' : 'Builder free! · $where',
            u.lab
                ? '${u.name} research is complete.'
                : '${u.name} is complete. Start your next upgrade.');
      }
    }
  }
}
