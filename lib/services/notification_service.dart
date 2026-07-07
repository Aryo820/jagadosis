import 'dart:developer';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/services/alarm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service managing local notification scheduling for medication reminders.
/// Schedules two notifications per medication time: 30 minutes and 15 minutes before.
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// The jam-H ringing alarm is delegated here. NotificationService stays the
  /// single façade every call site uses, so wiring the alarm in at each choke
  /// point keeps all schedule/cancel/reschedule flows in sync automatically.
  final AlarmService _alarmService = AlarmService();

  /// Android notification channel details
  ///
  /// [_channelIdBase] is only a prefix: the actual channel id encodes the
  /// sound/vibration preference (see [_channelIdFor]). On Android 8+ a channel's
  /// alert behaviour is fixed at creation, so using one channel per combination
  /// is the reliable way to make the sound/vibration toggles take effect when
  /// they change — a plain per-notification flag would be ignored.
  static const String _channelIdBase = 'jagadosis_reminders';
  static const String _channelName = 'Pengingat Obat';
  static const String _channelDescription =
      'Notifikasi pengingat untuk minum obat tepat waktu';

  /// Channel id for a given alert configuration.
  String _channelIdFor(bool sound, bool vibration) =>
      '${_channelIdBase}_s${sound ? 1 : 0}_v${vibration ? 1 : 0}';

  /// Reminder offsets in minutes before scheduled medication time
  static const List<int> _reminderOffsets = [30, 15];

  /// Maximum number of schedule times supported per medicine. Bounds both the
  /// notification-id encoding and the cancel sweep, so reducing a medicine's
  /// frequency (e.g. 4x → 2x) still clears its previously scheduled reminders.
  /// The UI currently allows up to 4; the headroom keeps ids stable if it grows.
  static const int _maxScheduleTimes = 8;

  /// Initializes the notification plugin, timezone data, and Android channel.
  /// Must be called once before any scheduling, typically in main().
  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    // flutter_timezone v5 returns a TimezoneInfo; use its IANA identifier.
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);

    // Request notification permissions on Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // Initialize the ringing-alarm subsystem alongside notifications.
    await _alarmService.init();
  }

  /// Schedules reminder notifications for a single medicine.
  /// Creates 2 notifications per schedule time (30 min and 15 min before).
  /// Only schedules if [medicine.enableNotification] is true.
  Future<void> scheduleForMedicine(MedicineModel medicine) async {
    // Also arm the jam-H ringing alarm. AlarmService applies the same
    // per-medicine and global gates internally.
    await _alarmService.scheduleForMedicine(medicine);

    // Honour both the per-medicine switch and the global reminder toggle. This
    // is the single choke point for scheduling, so gating here also covers
    // rescheduleAll() and the add/edit-medicine flow.
    if (!medicine.enableNotification) return;
    if (!PreferenceHandler.notificationGlobal) return;

    // Resolve the alert preferences once; they select the channel and are also
    // set on the notification so both agree.
    final bool soundOn = PreferenceHandler.notificationSound;
    final bool vibrationOn = PreferenceHandler.notificationVibration;
    final String channelId = _channelIdFor(soundOn, vibrationOn);

    final timeStrings = medicine.scheduleTime
        .split(',')
        .map((s) => s.trim())
        .toList();

    for (int timeIndex = 0; timeIndex < timeStrings.length; timeIndex++) {
      final timeParts = timeStrings[timeIndex].split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final scheduleTimeStr =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      for (
        int offsetIndex = 0;
        offsetIndex < _reminderOffsets.length;
        offsetIndex++
      ) {
        final offsetMinutes = _reminderOffsets[offsetIndex];
        final notificationId = _generateId(medicine.id, timeIndex, offsetIndex);

        // Calculate the notification time
        final scheduledDate = _nextInstanceOfTime(hour, minute, offsetMinutes);

        // Title and body vary by offset
        final String title;
        final String body;
        if (offsetMinutes == 30) {
          title = 'Pengingat Obat (30 menit lagi)';
          body =
              'Waktunya minum ${medicine.medicineName} pukul $scheduleTimeStr';
        } else {
          title = 'Segera Minum Obat (15 menit lagi)';
          body =
              'Jangan lupa minum ${medicine.medicineName} pukul $scheduleTimeStr';
        }

        try {
          await _plugin.zonedSchedule(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                _channelName,
                channelDescription: _channelDescription,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                // Kept consistent with the channel picked above; the settings
                // page reschedules when these change so a different channel
                // (with the new behaviour) is used for upcoming reminders.
                enableVibration: vibrationOn,
                playSound: soundOn,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          log(
            'NotificationService: Scheduled id=$notificationId for '
            '${medicine.medicineName} at ${scheduledDate.toString()} '
            '($offsetMinutes min before $scheduleTimeStr)',
          );
        } catch (e) {
          log('NotificationService: Failed to schedule id=$notificationId: $e');
        }
      }
    }
  }

  /// Cancels all scheduled notifications for a given medicine ID.
  Future<void> cancelForMedicine(String medicineId) async {
    // Clear the medicine's ringing alarms too.
    await _alarmService.cancelForMedicine(medicineId);

    // Sweep every possible slot (max supported times × offsets). Using the full
    // range — rather than the medicine's *current* time count — ensures a
    // medicine edited down to fewer times still has its old reminders cleared.
    for (int timeIndex = 0; timeIndex < _maxScheduleTimes; timeIndex++) {
      for (
        int offsetIndex = 0;
        offsetIndex < _reminderOffsets.length;
        offsetIndex++
      ) {
        final id = _generateId(medicineId, timeIndex, offsetIndex);
        await _plugin.cancel(id: id);
      }
    }
    log(
      'NotificationService: Cancelled all notifications for medicine $medicineId',
    );
  }

  /// Cancels every scheduled notification on the device.
  ///
  /// Called on sign-out so one user's reminders never linger for the next
  /// account signing in on a shared device.
  Future<void> cancelAll() async {
    await _alarmService.cancelAll();
    await _plugin.cancelAll();
    log('NotificationService: Cancelled all notifications');
  }

  /// Reschedules notifications for all medicines in the database.
  /// Cancels all existing notifications first, then re-creates them.
  /// Should be called on app startup.
  Future<void> rescheduleAll() async {
    await _plugin.cancelAll();
    // Clear stale ringing alarms; the loop below re-arms them per medicine via
    // scheduleForMedicine (which delegates to AlarmService).
    await _alarmService.cancelAll();

    // Never let a data-layer failure propagate: this runs at app startup and
    // right after login, where an unhandled throw would break launch or the
    // sign-in flow. A failed fetch simply means no reminders this pass.
    try {
      final repo = MedicineRepository();
      final medicines = await repo.getAllMedicines();

      for (final medicine in medicines) {
        // scheduleForMedicine itself gates on the per-medicine and global
        // toggles, so no need to re-check enableNotification here.
        await scheduleForMedicine(medicine);
      }

      log(
        'NotificationService: Rescheduled notifications for '
        '${medicines.length} medicines',
      );
    } catch (e) {
      log('NotificationService: rescheduleAll failed: $e');
    }
  }

  /// Generates a unique notification ID based on medicine ID, time index,
  /// and offset index. Uses hashCode to convert string ID to int.
  int _generateId(String medicineId, int timeIndex, int offsetIndex) {
    // Reserve `slotSpace` consecutive ids per medicine — one for every
    // (time × offset) combination — so a medicine's own reminders never clash.
    final int slotSpace = _maxScheduleTimes * _reminderOffsets.length;
    final int slotIndex = timeIndex * _reminderOffsets.length + offsetIndex;

    // Hash the medicine id into a base, spreading medicines across the full
    // positive 32-bit range Android notification ids allow. This widens the
    // id space ~1300x vs. the old %100000, making cross-medicine collisions
    // (which would silently overwrite another medicine's reminders) negligible.
    // base * slotSpace + slotIndex stays <= 2^31-1 by construction.
    final int base = medicineId.hashCode.abs() % (0x7FFFFFFF ~/ slotSpace);
    return base * slotSpace + slotIndex;
  }

  /// Calculates the next TZDateTime instance for [hour]:[minute] minus
  /// [offsetMinutes]. If the resulting time has already passed today,
  /// returns the same time tomorrow.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, int offsetMinutes) {
    final now = tz.TZDateTime.now(tz.local);

    int totalMinutes = hour * 60 + minute - offsetMinutes;

    // Normalize ke 0-1439 range (wrap around midnight safely)
    // Dengan ini, 00:10 - 30 menit = -20 -> +1440 = 1420 (23:40)
    while (totalMinutes < 0) {
      totalMinutes += 24 * 60;
    }
    final adjustedHour = (totalMinutes ~/ 60) % 24;
    final adjustedMinute = totalMinutes % 60;

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      adjustedHour,
      adjustedMinute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
