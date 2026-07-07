# Alarm sound

The looping sound played when a medication alarm fires is **`ggmu.mp3`**,
referenced by `AlarmService._alarmSound` in `lib/services/alarm_service.dart`.

To swap it: drop a new `.mp3` in this folder, update `_alarmSound` to match the
filename, and keep `assets/audio/` registered in `pubspec.yaml`.
