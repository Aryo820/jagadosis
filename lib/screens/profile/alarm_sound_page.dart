import 'dart:developer';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/services/alarm_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu nada dering yang bisa dipilih: [path] adalah nilai yang disimpan di
/// preferences dan diberikan ke plugin alarm (bisa path bawaan `assets/...`
/// atau path relatif ke folder Documents `alarm_sounds/...`); [name] adalah
/// label yang ditampilkan ke user.
class _SoundOption {
  const _SoundOption({required this.path, required this.name});
  final String path;
  final String name;
}

/// Memungkinkan user memilih nada dering alarm: pilih preset bawaan atau impor
/// file audio dari penyimpanan perangkat, masing-masing dengan pratinjau
/// putar/hentikan. Pilihan disimpan ke [PreferenceHandler] dan diterapkan ke
/// alarm berikutnya oleh pemanggilnya.
class AlarmSoundPage extends StatefulWidget {
  const AlarmSoundPage({super.key});

  @override
  State<AlarmSoundPage> createState() => _AlarmSoundPageState();
}

class _AlarmSoundPageState extends State<AlarmSoundPage> {
  /// Preset bawaan. Tambahkan entri lain di sini saat ada aset baru di
  /// `assets/audio/` (daftarkan juga di bawah `flutter:` pada pubspec.yaml).
  static const List<_SoundOption> _presets = [
    _SoundOption(
      path: PreferenceHandler.defaultAlarmSound,
      name: PreferenceHandler.defaultAlarmSoundName,
    ),
  ];

  final AudioPlayer _player = AudioPlayer();

  /// Path nada dering yang sedang dipilih (mencerminkan [PreferenceHandler.alarmSound]).
  late String _selectedPath;

  /// Nada dering yang diimpor dari perangkat pada sesi ini, ditampilkan sebagai
  /// opsi tambahan di bawah preset. Null jika suara tersimpan adalah preset.
  _SoundOption? _customOption;

  /// Path opsi yang sedang diputar sebagai pratinjau, atau null jika tidak ada yang diputar.
  String? _previewingPath;

  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selectedPath = PreferenceHandler.alarmSound;
    // Jika suara tersimpan adalah hasil impor, tampilkan sebagai opsi yang bisa
    // dipilih agar tetap terlihat dan bisa dipilih ulang di layar ini.
    if (!AlarmService.isAssetSound(_selectedPath)) {
      _customOption = _SoundOption(
        path: _selectedPath,
        name: PreferenceHandler.alarmSoundName,
      );
    }

    // Kembalikan ikon putar/hentikan ke "putar" begitu pratinjau selesai dengan sendirinya.
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _previewingPath = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Memutar pratinjau singkat [option], atau menghentikannya jika sedang diputar.
  /// Aset bawaan diputar lewat AssetSource; file impor lewat DeviceFileSource.
  Future<void> _togglePreview(_SoundOption option) async {
    if (_previewingPath == option.path) {
      await _player.stop();
      if (mounted) setState(() => _previewingPath = null);
      return;
    }

    await _player.stop();
    try {
      if (AlarmService.isAssetSound(option.path)) {
        // Path AssetSource dihitung relatif terhadap prefix `assets/` di pubspec.
        await _player.play(AssetSource(option.path.replaceFirst('assets/', '')));
      } else {
        final abs = await AlarmService.resolveAbsolutePath(option.path);
        if (abs == null) return;
        await _player.play(DeviceFileSource(abs));
      }
      if (mounted) setState(() => _previewingPath = option.path);
    } catch (e) {
      log('AlarmSoundPage: preview failed for ${option.path}: $e');
      if (mounted) {
        setState(() => _previewingPath = null);
        _showSnack('Gagal memutar pratinjau suara');
      }
    }
  }

  /// Membuka file picker sistem, menyalin audio yang dipilih ke penyimpanan aplikasi,
  /// lalu memilihnya. Salinan ini menjaga suara tetap bisa diputar meski file asli
  /// berpindah atau cache picker dibersihkan.
  Future<void> _importFromDevice() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      final sourcePath = result?.files.single.path;
      if (sourcePath == null) return; // Dibatalkan atau path tidak dapat diakses.

      final relativePath = await AlarmService.importCustomSound(sourcePath);
      final name = result!.files.single.name;

      await _player.stop();
      setState(() {
        _customOption = _SoundOption(path: relativePath, name: name);
        _selectedPath = relativePath;
        _previewingPath = null;
      });
    } catch (e) {
      log('AlarmSoundPage: import failed: $e');
      _showSnack('Gagal mengambil file audio');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _select(String path) {
    setState(() => _selectedPath = path);
  }

  /// Menyimpan pilihan, memasang ulang alarm agar berlaku, lalu kembali ke layar sebelumnya.
  Future<void> _save() async {
    final option = [..._presets, ?_customOption]
        .firstWhere((o) => o.path == _selectedPath, orElse: () => _presets.first);

    await _player.stop();
    await PreferenceHandler.setAlarmSound(option.path, option.name);
    // Suara sudah tertanam di tiap AlarmSettings saat penjadwalan, jadi jadwal
    // perlu dibangun ulang agar nada dering baru berlaku untuk alarm berikutnya.
    if (PreferenceHandler.notificationGlobal) {
      await AlarmService().rescheduleAll();
    }
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final options = [..._presets, ?_customOption];

    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Suara Alarm',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'Pilih Nada Dering',
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
                      border:
                          Border.all(color: AppColors.outlineVariant.withAlpha(50)),
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
                        for (int i = 0; i < options.length; i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                                color: Color(0xFFF1F3F9)),
                          _buildSoundTile(options[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  // Impor dari perangkat
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importing ? null : _importFromDevice,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.medicalBlue,
                        side: const BorderSide(
                            color: AppColors.medicalBlue, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.library_music_outlined),
                      label: Text(
                        _importing ? 'Memuat...' : 'Pilih Lagu dari HP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bilah tombol simpan
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12.0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wellnessGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    'Simpan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTile(_SoundOption option) {
    final selected = option.path == _selectedPath;
    final previewing = option.path == _previewingPath;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _select(option.path),
      leading: IconButton(
        icon: Icon(
          previewing ? Icons.stop_circle_rounded : Icons.play_circle_outline_rounded,
          color: AppColors.medicalBlue,
          size: 32,
        ),
        onPressed: () => _togglePreview(option),
      ),
      title: Text(
        option.name,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          fontSize: 15,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.wellnessGreen)
          : const Icon(Icons.radio_button_unchecked_rounded,
              color: AppColors.outlineVariant),
    );
  }
}
