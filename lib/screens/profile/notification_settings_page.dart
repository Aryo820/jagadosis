import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/screens/profile/alarm_sound_page.dart';
import 'package:aplikasi/services/notification_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late bool _globalEnabled;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late int _snoozeMinutes;
  late String _alarmSoundName;

  final List<int> _snoozeOptions = [5, 10, 15, 30, 60];
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _globalEnabled = PreferenceHandler.notificationGlobal;
    _soundEnabled = PreferenceHandler.notificationSound;
    _vibrationEnabled = PreferenceHandler.notificationVibration;
    _snoozeMinutes = PreferenceHandler.notificationSnooze;
    _alarmSoundName = PreferenceHandler.alarmSoundName;
  }

  /// Membuka pemilih nada dering, lalu menyegarkan nama yang ditampilkan.
  /// Pemilih itu sendiri yang menyimpan pilihan dan menjadwalkan ulang alarm,
  /// jadi di sini kita cukup membaca ulang labelnya.
  Future<void> _openSoundPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlarmSoundPage()),
    );
    // Push di atas baru selesai ketika pengguna keluar dari pemilih, jadi
    // halaman ini bisa saja sudah tidak terpasang lagi. Periksa dulu sebelum
    // memanggil setState.
    if (!mounted) return;
    setState(() {
      _alarmSoundName = PreferenceHandler.alarmSoundName;
    });
  }

  Future<void> _updateGlobal(bool value) async {
    // Simpan dulu supaya proses penjadwalan membaca nilai yang baru, lalu
    // terapkan: mematikan pengingat akan menghapus semua yang sudah dijadwalkan;
    // menyalakannya kembali akan menyusun ulang jadwal dari daftar obat pengguna.
    await PreferenceHandler.setNotificationGlobal(value);
    if (!mounted) return;
    setState(() {
      _globalEnabled = value;
    });
    if (value) {
      await _notificationService.rescheduleAll();
    } else {
      await _notificationService.cancelAll();
    }
  }

  Future<void> _updateSound(bool value) async {
    await PreferenceHandler.setNotificationSound(value);
    if (!mounted) return;
    setState(() {
      _soundEnabled = value;
    });
    // Suara/getaran ditanamkan ke notifikasi saat penjadwalan, jadi jadwal
    // harus disusun ulang agar perubahan berlaku pada pengingat berikutnya.
    await _reapplyIfEnabled();
  }

  Future<void> _updateVibration(bool value) async {
    await PreferenceHandler.setNotificationVibration(value);
    if (!mounted) return;
    setState(() {
      _vibrationEnabled = value;
    });
    await _reapplyIfEnabled();
  }

  /// Menjadwalkan ulang untuk menerapkan perubahan preferensi peringatan, tetapi
  /// hanya jika pengingat global sedang aktif (kalau tidak, tak ada jadwal yang
  /// perlu diperbarui).
  Future<void> _reapplyIfEnabled() async {
    if (_globalEnabled) {
      await _notificationService.rescheduleAll();
    }
  }

  Future<void> _updateSnooze(int? value) async {
    if (value != null) {
      await PreferenceHandler.setNotificationSnooze(value);
      if (!mounted) return;
      setState(() {
        _snoozeMinutes = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Pengaturan Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informasi
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.primaryContainer.withAlpha(120)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.medicalBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Atur bagaimana aplikasi mengingatkan Anda untuk meminum obat secara tepat waktu.',
                      style: GoogleFonts.inter(
                        fontSize: 13.0,
                        color: AppColors.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Sakelar notifikasi global
            Text(
              'Umum',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.medicalBlue.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.medicalBlue),
                ),
                title: Text(
                  'Aktifkan Pengingat',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Dapatkan notifikasi alarm jadwal obat',
                  style: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 12),
                ),
                trailing: Switch.adaptive(
                  value: _globalEnabled,
                  activeThumbColor: AppColors.wellnessGreen,
                  onChanged: _updateGlobal,
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Bagian pengaturan perilaku peringatan
            AnimatedOpacity(
              opacity: _globalEnabled ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_globalEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metode Peringatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Sakelar suara
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.wellnessGreen.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.volume_up_outlined, color: AppColors.wellnessGreen),
                            ),
                            title: Text(
                              'Suara Alarm',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 15,
                              ),
                            ),
                            trailing: Switch.adaptive(
                              value: _soundEnabled,
                              activeThumbColor: AppColors.wellnessGreen,
                              onChanged: _updateSound,
                            ),
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F3F9)),
                          // Sakelar getaran
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.vibration_rounded, color: Colors.orange),
                            ),
                            title: Text(
                              'Getaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 15,
                              ),
                            ),
                            trailing: Switch.adaptive(
                              value: _vibrationEnabled,
                              activeThumbColor: AppColors.wellnessGreen,
                              onChanged: _updateVibration,
                            ),
                          ),
                          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F3F9)),
                          // Pemilih nada dering
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            onTap: _openSoundPicker,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.medicalBlue.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.music_note_rounded, color: AppColors.medicalBlue),
                            ),
                            title: Text(
                              'Nada Dering',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              _alarmSoundName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Bagian interval snooze / pengingat ulang
                    Text(
                      'Interval Pengingat Ulang (Snooze)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.snooze_rounded, color: Colors.purple),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jeda Pengingat',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Ulangi alarm jika belum diminum',
                                        style: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<int>(
                            value: _snoozeMinutes,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                            dropdownColor: AppColors.surfaceWhite,
                            style: GoogleFonts.inter(
                              color: AppColors.medicalBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            items: _snoozeOptions.map((opt) {
                              return DropdownMenuItem<int>(
                                value: opt,
                                child: Text('$opt Menit'),
                              );
                            }).toList(),
                            onChanged: _updateSnooze,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
