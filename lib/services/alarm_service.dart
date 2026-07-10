import 'dart:developer';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Singleton yang mengatur alarm obat yang *berbunyi* tepat pada waktu dosis
/// terjadwal (jam H), sebagai pelengkap pengingat awal 30/15 menit yang ditangani
/// oleh NotificationService.
///
/// Berbeda dari flutter_local_notifications, paket `alarm` menjadwalkan alarm
/// sekali-jalan (one-shot) pada [DateTime] yang konkret — tidak ada flag ulang
/// harian. Karena itu pengulangan harian ditiru (emulasi) dengan cara:
///   * [scheduleForMedicine] menetapkan kemunculan terdekat berikutnya dari tiap waktu,
///   * setelah dosis dikonfirmasi dari layar alarm, obat itu diaktifkan ulang
///     lewat [scheduleForMedicine] (kemunculan berikutnya = besok),
///   * [rescheduleAll] juga berjalan saat aplikasi dimulai dan saat aplikasi
///     kembali aktif, sebagai jaring pengaman.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  /// Subdirektori (relatif terhadap folder Documents aplikasi) tempat nada dering
  /// yang dipilih dari penyimpanan perangkat disalin. Plugin alarm menerima jalur
  /// relatif-Documents yang sama ini, jadi nilainya sekaligus dipakai sebagai
  /// nilai [PreferenceHandler] yang disimpan untuk suara pilihan pengguna.
  static const String customSoundDir = 'alarm_sounds';

  /// Meniru NotificationService: membatasi penyusunan id dan proses pembersihan
  /// (cancel) agar mengurangi frekuensi obat tetap membersihkan alarm lamanya.
  static const int _maxScheduleTimes = 8;

  /// Menginisialisasi plugin alarm. Harus dipanggil sekali sebelum penjadwalan.
  Future<void> init() async {
    await Alarm.init();
  }

  /// Menjadwalkan alarm berbunyi pada setiap waktu dosis untuk satu obat.
  /// Menghormati sakelar per-obat maupun sakelar pengingat global, jadi ini
  /// adalah satu-satunya titik utama penjadwalan alarm.
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

  /// Membangun AlarmSettings untuk satu dosis. Nama obat dan waktunya dibawa di
  /// dalam isi notifikasi agar layar alarm bisa menampilkannya dari AlarmSettings
  /// yang diterimanya.
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
      // Aset bawaan (`assets/...`) atau suara kustom relatif-Documents
      // (`alarm_sounds/...`); plugin alarm menerima kedua bentuk ini langsung.
      assetAudioPath: PreferenceHandler.alarmSound,
      loopAudio: true,
      vibrate: vibrationOn,
      // Suara mati → jaga tetap senyap (hanya getar), selain itu naik perlahan
      // (fade) hingga volume penuh.
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

  /// Membangun ulang pengaturan alarm yang sudah ada dengan waktu bunyi baru,
  /// sambil mempertahankan id, suara, dan payload notifikasinya. Dibangun ulang
  /// lewat constructor, bukan copyWith, agar tidak bergantung pada keberadaan
  /// metode tersebut.
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

  /// Mengaktifkan ulang alarm berbunyi [delay] dari sekarang, dengan memakai
  /// kembali id dan payload-nya. Dipakai oleh tombol Tunda (Snooze) di layar alarm.
  Future<void> snooze(AlarmSettings from, Duration delay) async {
    final next = DateTime.now().add(delay);
    try {
      // Hentikan bunyi yang sedang berlangsung sebelum mengaktifkan ulang slot yang sama.
      await Alarm.stop(from.id);
      await Alarm.set(alarmSettings: _withDateTime(from, next));
      log('AlarmService: Snoozed alarm id=${from.id} until $next');
    } catch (e) {
      log('AlarmService: Failed to snooze alarm id=${from.id}: $e');
    }
  }

  /// Membatalkan setiap slot alarm untuk sebuah obat. Menyapu seluruh rentang
  /// slot — bukan jumlah waktu obat saat ini — agar obat yang diedit menjadi
  /// lebih sedikit waktunya tetap terbersihkan alarm lamanya.
  Future<void> cancelForMedicine(String medicineId) async {
    for (int timeIndex = 0; timeIndex < _maxScheduleTimes; timeIndex++) {
      final id = _generateId(medicineId, timeIndex);
      await Alarm.stop(id);
    }
    log('AlarmService: Cancelled all alarms for medicine $medicineId');
  }

  /// Membatalkan seluruh alarm terjadwal di perangkat (misalnya saat logout).
  Future<void> cancelAll() async {
    await Alarm.stopAll();
    log('AlarmService: Cancelled all alarms');
  }

  /// Membatalkan semua alarm lalu mengaktifkan ulang kemunculan berikutnya untuk
  /// setiap obat. Tidak pernah melempar error: fungsi ini berjalan saat aplikasi
  /// dimulai, setelah login, dan setelah sebuah alarm dimatikan, di mana error
  /// yang tak tertangani bisa merusak proses buka aplikasi atau alur alarm.
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

  /// [hour]:[minute] berikutnya dari sekarang. Jika waktu hari ini sudah lewat,
  /// mengembalikan waktu yang sama untuk besok.
  DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  /// Id alarm yang deterministik dan tahan-tabrakan, dibentuk dari id obat + slot
  /// waktu. Idenya sama seperti NotificationService._generateId, tetapi satu id
  /// per (obat, waktu) karena alarm berbunyi tidak punya varian per-selisih.
  int _generateId(String medicineId, int timeIndex) {
    final int base =
        medicineId.hashCode.abs() % (0x7FFFFFFF ~/ _maxScheduleTimes);
    return base * _maxScheduleTimes + timeIndex;
  }

  /// Memetakan balik id alarm berbunyi ke obat dan slot dosis pemiliknya, dengan
  /// menghitung ulang id tiap obat untuk slot waktu yang tersandi (encoded).
  /// Mengembalikan null jika tidak ada obat saat ini yang cocok (misalnya sudah
  /// dihapus), atau saat terjadi error di lapisan data. Memungkinkan layar alarm
  /// menandai slot yang tepat sebagai sudah diminum.
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

  /// Bernilai true jika [soundPath] merupakan aset Flutter bawaan, bukan file
  /// pilihan pengguna yang berada di dalam folder Documents aplikasi.
  static bool isAssetSound(String soundPath) => soundPath.startsWith('assets/');

  /// Mengubah nilai nada dering tersimpan menjadi jalur file absolut untuk
  /// pemutaran pratinjau. Aset bawaan mengembalikan null (diputar lewat
  /// AssetSource, bukan jalur file); suara kustom mengembalikan lokasi absolutnya
  /// di dalam folder Documents.
  static Future<String?> resolveAbsolutePath(String soundPath) async {
    if (isAssetSound(soundPath)) return null;
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, soundPath);
  }

  /// Menyalin file audio yang dipilih ke folder Documents aplikasi dan
  /// mengembalikan jalur relatif-Documents (misal `alarm_sounds/song.mp3`) untuk
  /// disimpan di preferensi dan diserahkan ke plugin alarm. Mempertahankan nama
  /// file aslinya.
  static Future<String> importCustomSound(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(dir.path, customSoundDir));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final fileName = p.basename(sourcePath);
    final destPath = p.join(destDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return p.join(customSoundDir, fileName);
  }
}
