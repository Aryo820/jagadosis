import 'dart:developer';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/services/alarm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Layanan singleton yang mengatur penjadwalan notifikasi lokal untuk pengingat obat.
/// Untuk setiap waktu minum obat, dijadwalkan dua notifikasi: 30 menit dan 15 menit sebelumnya.
class NotificationService {
  // Pola singleton (hanya ada satu instance)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Alarm berbunyi tepat pada jam-H didelegasikan ke sini. NotificationService
  /// menjadi satu-satunya pintu (façade) yang dipakai semua pemanggil, jadi dengan
  /// menautkan alarm di tiap titik penting, seluruh alur jadwal/batal/jadwal ulang
  /// otomatis selalu selaras.
  final AlarmService _alarmService = AlarmService();

  /// Detail channel notifikasi Android
  ///
  /// [_channelIdBase] hanyalah awalan (prefix): id channel sebenarnya menyertakan
  /// preferensi suara/getar (lihat [_channelIdFor]). Pada Android 8+ perilaku
  /// peringatan sebuah channel dikunci saat channel dibuat, jadi memakai satu
  /// channel untuk tiap kombinasi adalah cara andal agar tombol suara/getar
  /// benar-benar berefek saat diubah — sekadar flag per-notifikasi akan diabaikan.
  static const String _channelIdBase = 'jagadosis_reminders';
  static const String _channelName = 'Pengingat Obat';
  static const String _channelDescription =
      'Notifikasi pengingat untuk minum obat tepat waktu';

  /// Id channel untuk konfigurasi peringatan tertentu (suara/getar).
  String _channelIdFor(bool sound, bool vibration) =>
      '${_channelIdBase}_s${sound ? 1 : 0}_v${vibration ? 1 : 0}';

  /// Selisih waktu pengingat (dalam menit) sebelum jadwal minum obat
  static const List<int> _reminderOffsets = [30, 15];

  /// Jumlah maksimum waktu jadwal yang didukung per obat. Membatasi baik
  /// penyusunan id-notifikasi maupun proses pembersihan (cancel), sehingga saat
  /// frekuensi sebuah obat dikurangi (misal 4x → 2x), pengingat lama yang sudah
  /// dijadwalkan tetap ikut dibersihkan. UI saat ini memperbolehkan hingga 4;
  /// cadangan ini menjaga id tetap stabil bila nanti jumlahnya bertambah.
  static const int _maxScheduleTimes = 8;

  /// Menginisialisasi plugin notifikasi, data timezone, dan channel Android.
  /// Harus dipanggil sekali sebelum penjadwalan apa pun, biasanya di main().
  Future<void> init() async {
    // Inisialisasi database timezone
    tz.initializeTimeZones();
    // flutter_timezone v5 mengembalikan TimezoneInfo; pakai identifier IANA-nya.
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    // Pengaturan inisialisasi untuk Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);

    // Minta izin notifikasi pada Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // Inisialisasi juga subsistem alarm berbunyi bersama notifikasi.
    await _alarmService.init();
  }

  /// Menjadwalkan notifikasi pengingat untuk satu obat.
  /// Membuat 2 notifikasi per waktu jadwal (30 menit dan 15 menit sebelumnya).
  /// Hanya dijadwalkan jika [medicine.enableNotification] bernilai true.
  Future<void> scheduleForMedicine(MedicineModel medicine) async {
    // Aktifkan juga alarm berbunyi jam-H. AlarmService menerapkan pembatasan
    // per-obat dan pembatasan global yang sama secara internal.
    await _alarmService.scheduleForMedicine(medicine);

    // Hormati sakelar per-obat maupun sakelar pengingat global. Ini adalah satu-
    // satunya titik utama penjadwalan, jadi pengecekan di sini juga mencakup
    // rescheduleAll() serta alur tambah/edit obat.
    if (!medicine.enableNotification) return;
    if (!PreferenceHandler.notificationGlobal) return;

    // Ambil preferensi peringatan sekali saja; nilai ini memilih channel dan
    // sekaligus dipasang pada notifikasi agar keduanya konsisten.
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

        // Hitung waktu munculnya notifikasi
        final scheduledDate = _nextInstanceOfTime(hour, minute, offsetMinutes);

        // Judul dan isi berbeda tergantung selisih waktunya
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
                // Dibuat konsisten dengan channel yang dipilih di atas; halaman
                // pengaturan menjadwalkan ulang saat nilai ini berubah, sehingga
                // channel berbeda (dengan perilaku baru) dipakai untuk pengingat
                // berikutnya.
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

  /// Membatalkan semua notifikasi terjadwal untuk ID obat tertentu.
  Future<void> cancelForMedicine(String medicineId) async {
    // Hapus juga alarm berbunyi milik obat tersebut.
    await _alarmService.cancelForMedicine(medicineId);

    // Sapu setiap slot yang mungkin (maksimum waktu yang didukung × selisih).
    // Memakai rentang penuh — bukan jumlah waktu obat *saat ini* — memastikan
    // obat yang diedit menjadi lebih sedikit waktunya tetap terbersihkan
    // pengingat lamanya.
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

  /// Membatalkan seluruh notifikasi terjadwal di perangkat.
  ///
  /// Dipanggil saat logout agar pengingat milik satu pengguna tidak tertinggal
  /// untuk akun berikutnya yang login di perangkat yang sama.
  Future<void> cancelAll() async {
    await _alarmService.cancelAll();
    await _plugin.cancelAll();
    log('NotificationService: Cancelled all notifications');
  }

  /// Menjadwalkan ulang notifikasi untuk semua obat di database.
  /// Membatalkan semua notifikasi yang ada terlebih dahulu, lalu membuatnya kembali.
  /// Sebaiknya dipanggil saat aplikasi dimulai.
  Future<void> rescheduleAll() async {
    await _plugin.cancelAll();
    // Bersihkan alarm berbunyi yang usang; perulangan di bawah mengaktifkannya
    // kembali per obat lewat scheduleForMedicine (yang mendelegasikan ke AlarmService).
    await _alarmService.cancelAll();

    // Jangan pernah biarkan kegagalan di lapisan data menyebar: fungsi ini berjalan
    // saat aplikasi dimulai dan tepat setelah login, di mana error yang tak tertangani
    // bisa merusak proses buka aplikasi atau alur login. Jika pengambilan data gagal,
    // artinya cukup tidak ada pengingat pada putaran ini.
    try {
      final repo = MedicineRepository();
      final medicines = await repo.getAllMedicines();

      for (final medicine in medicines) {
        // scheduleForMedicine sudah melakukan pengecekan pada sakelar per-obat
        // dan global, jadi tidak perlu memeriksa enableNotification lagi di sini.
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

  /// Menghasilkan ID notifikasi unik berdasarkan ID obat, indeks waktu, dan
  /// indeks selisih. Memakai hashCode untuk mengubah ID string menjadi int.
  int _generateId(String medicineId, int timeIndex, int offsetIndex) {
    // Sisihkan `slotSpace` id berurutan untuk tiap obat — satu untuk setiap
    // kombinasi (waktu × selisih) — agar pengingat milik satu obat tidak
    // pernah bertabrakan.
    final int slotSpace = _maxScheduleTimes * _reminderOffsets.length;
    final int slotIndex = timeIndex * _reminderOffsets.length + offsetIndex;

    // Hash-kan id obat menjadi nilai dasar (base), menyebarkan obat-obat ke
    // seluruh rentang 32-bit positif yang diizinkan untuk id notifikasi Android.
    // Ini memperluas ruang id ~1300x dibanding %100000 yang lama, sehingga
    // tabrakan antar-obat (yang bisa diam-diam menimpa pengingat obat lain)
    // menjadi sangat kecil kemungkinannya.
    // base * slotSpace + slotIndex dijamin tetap <= 2^31-1 secara konstruksi.
    final int base = medicineId.hashCode.abs() % (0x7FFFFFFF ~/ slotSpace);
    return base * slotSpace + slotIndex;
  }

  /// Menghitung TZDateTime berikutnya untuk [hour]:[minute] dikurangi
  /// [offsetMinutes]. Jika waktu hasilnya sudah lewat hari ini, mengembalikan
  /// waktu yang sama untuk besok.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, int offsetMinutes) {
    final now = tz.TZDateTime.now(tz.local);

    int totalMinutes = hour * 60 + minute - offsetMinutes;

    // Normalkan ke rentang 0-1439 (melewati tengah malam dengan aman)
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

    // Jika waktunya sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
