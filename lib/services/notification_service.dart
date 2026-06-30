import 'dart:developer';

import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
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

  /// Android notification channel details
  static const String _channelId = 'jagadosis_reminders';
  static const String _channelName = 'Pengingat Obat';
  static const String _channelDescription =
      'Notifikasi pengingat untuk minum obat tepat waktu';

  /// Reminder offsets in minutes before scheduled medication time
  static const List<int> _reminderOffsets = [30, 15];

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
  }

  /// Schedules reminder notifications for a single medicine.
  /// Creates 2 notifications per schedule time (30 min and 15 min before).
  /// Only schedules if [medicine.enableNotification] is true.
  Future<void> scheduleForMedicine(MedicineModel medicine) async {
    if (!medicine.enableNotification) return;

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
                _channelId,
                _channelName,
                channelDescription: _channelDescription,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                enableVibration: true,
                playSound: true,
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
    // Cancel for up to 4 schedule times × 2 offsets = 8 notifications max
    for (int timeIndex = 0; timeIndex < 4; timeIndex++) {
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

  /// Reschedules notifications for all medicines in the database.
  /// Cancels all existing notifications first, then re-creates them.
  /// Should be called on app startup.
  Future<void> rescheduleAll() async {
    await _plugin.cancelAll();

    final repo = MedicineRepository();
    final medicines = await repo.getAllMedicines();

    for (final medicine in medicines) {
      if (medicine.hasPendingSlot && medicine.enableNotification) {
        await scheduleForMedicine(medicine);
      }
    }

    log(
      'NotificationService: Rescheduled notifications for ${medicines.length} medicines',
    );
  }

  /// Generates a unique notification ID based on medicine ID, time index,
  /// and offset index. Uses hashCode to convert string ID to int.
  int _generateId(String medicineId, int timeIndex, int offsetIndex) {
    // Ensure positive and within 32-bit int range
    final base = medicineId.hashCode.abs() % 100000;
    return base * 10 + timeIndex * 2 + offsetIndex;
  }

  /// Calculates the next TZDateTime instance for [hour]:[minute] minus
  /// [offsetMinutes]. If the resulting time has already passed today,
  /// returns the same time tomorrow.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, int offsetMinutes) {
    final now = tz.TZDateTime.now(tz.local);

    // Subtract the reminder offset from the scheduled medication time
    final totalMinutes = hour * 60 + minute - offsetMinutes;
    final adjustedHour = (totalMinutes ~/ 60) % 24;
    final adjustedMinute = totalMinutes % 60;

    // Handle negative minutes (e.g. 00:10 - 30 min = previous day 23:40)
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      adjustedHour < 0 ? adjustedHour + 24 : adjustedHour,
      adjustedMinute < 0 ? adjustedMinute + 60 : adjustedMinute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
