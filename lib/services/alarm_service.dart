import 'dart:developer';

import 'package:alarm/alarm.dart';
import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';

/// Singleton managing the *ringing* medication alarm that fires exactly at the
/// scheduled dose time (jam H), on top of the 30/15-minute heads-up reminders
/// handled by NotificationService.
///
/// Unlike flutter_local_notifications, the `alarm` package schedules one-shot
/// alarms at a concrete [DateTime] — there is no daily-repeat flag. Daily
/// recurrence is therefore emulated:
///   * [scheduleForMedicine] sets the next upcoming occurrence of each time,
///   * after a dose is confirmed from the ring screen it re-arms that medicine
///     via [scheduleForMedicine] (next occurrence = tomorrow),
///   * [rescheduleAll] also runs at startup and on app resume as a safety net.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  /// Bundled looping alarm sound.
  static const String _alarmSound = 'assets/audio/ggmu.mp3';

  /// Mirrors NotificationService: bounds the id encoding and the cancel sweep so
  /// reducing a medicine's frequency still clears its old alarms.
  static const int _maxScheduleTimes = 8;

  /// Initializes the alarm plugin. Must be called once before scheduling.
  Future<void> init() async {
    await Alarm.init();
  }

  /// Schedules a ringing alarm at each dose time for a single medicine.
  /// Honours both the per-medicine switch and the global reminder toggle, so
  /// this is the single choke point for alarm scheduling.
  Future<void> scheduleForMedicine(MedicineModel medicine) async {
    if (!medicine.enableNotification) return;
    if (!PreferenceHandler.notificationGlobal) return;

    final times = medicine.scheduleTimes;
    for (int timeIndex = 0; timeIndex < times.length; timeIndex++) {
      final parts = times[timeIndex].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final id = _generateId(medicine.id, timeIndex);
      final when = _nextOccurrence(hour, minute);
      final timeLabel =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      try {
        await Alarm.set(
          alarmSettings: _buildSettings(
            id: id,
            when: when,
            medicineName: medicine.medicineName,
            timeLabel: timeLabel,
          ),
        );
        log(
          'AlarmService: Scheduled alarm id=$id for ${medicine.medicineName} '
          'at ${when.toString()} ($timeLabel)',
        );
      } catch (e) {
        log('AlarmService: Failed to schedule alarm id=$id: $e');
      }
    }
  }

  /// Builds the AlarmSettings for a dose. The medicine name and time are carried
  /// in the notification body so the ring screen can display them from the
  /// AlarmSettings it receives.
  AlarmSettings _buildSettings({
    required int id,
    required DateTime when,
    required String medicineName,
    required String timeLabel,
  }) {
    final bool soundOn = PreferenceHandler.notificationSound;
    final bool vibrationOn = PreferenceHandler.notificationVibration;

    return AlarmSettings(
      id: id,
      dateTime: when,
      assetAudioPath: _alarmSound,
      loopAudio: true,
      vibrate: vibrationOn,
      // Sound off → keep it silent (vibrate-only), otherwise fade up to full.
      volumeSettings: VolumeSettings.fade(
        volume: soundOn ? 1.0 : 0.0,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: 'Waktunya Minum Obat',
        body: 'Saatnya minum $medicineName pukul $timeLabel',
        stopButton: 'Matikan',
        icon: 'ic_launcher',
      ),
      androidFullScreenIntent: true,
      warningNotificationOnKill: false,
    );
  }

  /// Rebuilds an existing alarm's settings with a new fire time, preserving its
  /// id, sound, and notification payload. Reconstructs via the constructor
  /// rather than copyWith so it doesn't depend on that method existing.
  AlarmSettings _withDateTime(AlarmSettings from, DateTime when) {
    return AlarmSettings(
      id: from.id,
      dateTime: when,
      assetAudioPath: from.assetAudioPath,
      loopAudio: from.loopAudio,
      vibrate: from.vibrate,
      volumeSettings: from.volumeSettings,
      notificationSettings: from.notificationSettings,
      androidFullScreenIntent: from.androidFullScreenIntent,
      warningNotificationOnKill: from.warningNotificationOnKill,
    );
  }

  /// Re-arms a ringing alarm [delay] from now, reusing its id and payload.
  /// Used by the ring screen's Snooze button.
  Future<void> snooze(AlarmSettings from, Duration delay) async {
    final next = DateTime.now().add(delay);
    try {
      // Silence the current ring before re-arming the same slot.
      await Alarm.stop(from.id);
      await Alarm.set(alarmSettings: _withDateTime(from, next));
      log('AlarmService: Snoozed alarm id=${from.id} until $next');
    } catch (e) {
      log('AlarmService: Failed to snooze alarm id=${from.id}: $e');
    }
  }

  /// Cancels every alarm slot for a medicine. Sweeps the full slot range — not
  /// the medicine's current time count — so a medicine edited down to fewer
  /// times still has its old alarms cleared.
  Future<void> cancelForMedicine(String medicineId) async {
    for (int timeIndex = 0; timeIndex < _maxScheduleTimes; timeIndex++) {
      final id = _generateId(medicineId, timeIndex);
      await Alarm.stop(id);
    }
    log('AlarmService: Cancelled all alarms for medicine $medicineId');
  }

  /// Cancels every scheduled alarm on the device (e.g. on sign-out).
  Future<void> cancelAll() async {
    await Alarm.stopAll();
    log('AlarmService: Cancelled all alarms');
  }

  /// Cancels all alarms then re-arms the next occurrence for every medicine.
  /// Never throws: this runs at startup, after login, and after an alarm is
  /// dismissed, where an unhandled throw would break launch or the ring flow.
  Future<void> rescheduleAll() async {
    await Alarm.stopAll();
    try {
      final medicines = await MedicineRepository().getAllMedicines();
      for (final medicine in medicines) {
        await scheduleForMedicine(medicine);
      }
      log('AlarmService: Rescheduled alarms for ${medicines.length} medicines');
    } catch (e) {
      log('AlarmService: rescheduleAll failed: $e');
    }
  }

  /// Next [hour]:[minute] from now. If today's time has already passed,
  /// returns the same time tomorrow.
  DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  /// Deterministic, collision-resistant alarm id from medicine id + time slot.
  /// Same idea as NotificationService._generateId, but one id per (medicine,
  /// time) since a ringing alarm has no per-offset variants.
  int _generateId(String medicineId, int timeIndex) {
    final int base =
        medicineId.hashCode.abs() % (0x7FFFFFFF ~/ _maxScheduleTimes);
    return base * _maxScheduleTimes + timeIndex;
  }

  /// Reverse-maps a ringing alarm's id back to the medicine and dose slot it
  /// belongs to, by recomputing each medicine's id for the encoded time slot.
  /// Returns null if no current medicine matches (e.g. it was deleted), or on
  /// a data-layer error. Lets the ring screen mark the right slot as taken.
  Future<({MedicineModel medicine, int timeIndex})?> resolveSlot(
    int alarmId,
  ) async {
    final timeIndex = alarmId % _maxScheduleTimes;
    try {
      final medicines = await MedicineRepository().getAllMedicines();
      for (final m in medicines) {
        if (_generateId(m.id, timeIndex) == alarmId) {
          return (medicine: m, timeIndex: timeIndex);
        }
      }
    } catch (e) {
      log('AlarmService: resolveSlot failed for id=$alarmId: $e');
    }
    return null;
  }
}
