import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/history_model.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/history_repository.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onAddMedTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onFamilyTap;

  const HomePage({
    super.key,
    this.onAddMedTap,
    this.onHistoryTap,
    this.onFamilyTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MedicineRepository _medicineRepo = MedicineRepository();
  final HistoryRepository _historyRepo = HistoryRepository();

  List<MedicineModel> _medicines = [];
  bool _isLoading = true;
  MedicineModel? _nextPendingMedicine;
  int _adherencePercent = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Parses a scheduleTime string (e.g. "08:00" or "08:00, 20:00") and
  /// returns true if ALL times in the schedule have already passed today.
  bool _allTimesHavePassed(String scheduleTime) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    // scheduleTime can be "08:00" or "08:00, 20:00"
    final parts = scheduleTime.split(',').map((s) => s.trim()).toList();
    for (final part in parts) {
      final timeParts = part.split(':');
      if (timeParts.length != 2) continue;
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final scheduleMinutes = hour * 60 + minute;
      if (scheduleMinutes >= nowMinutes) {
        // At least one scheduled time has NOT passed yet
        return false;
      }
    }
    return true;
  }

  /// Checks all pending medicines and marks them as 'missed' if their
  /// schedule time has already passed. Updates the medicine status and
  /// adds a history entry with status 'missed'.
  Future<void> _checkAndMarkMissed(List<MedicineModel> medicines) async {
    for (final med in medicines) {
      if (med.status == 'pending' && _allTimesHavePassed(med.scheduleTime)) {
        // 1. Update medicine status to 'missed'
        final updatedMed = med.copyWith(status: 'missed');
        await _medicineRepo.updateMedicine(updatedMed);

        // 2. Add record to history table with 'missed' status
        final history = HistoryModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${med.id}',
          medicineName: med.medicineName,
          takenAt: DateTime.now(),
          status: 'missed',
        );
        await _historyRepo.addHistory(history);
      }
    }
  }

  /// Refreshes lists, calculates adherence progress, and determines the next pending medicine.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // First pass: detect and mark any overdue pending medicines as missed
      final rawList = await _medicineRepo.getAllMedicines();
      await _checkAndMarkMissed(rawList);

      // Re-fetch after possible status changes
      final list = await _medicineRepo.getAllMedicines();

      // Sort medicines by schedule time (e.g. "08:00")
      list.sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

      int takenCount = 0;
      int missedCount = 0;
      MedicineModel? nextPending;

      for (final med in list) {
        if (med.status == 'taken') {
          takenCount++;
        } else if (med.status == 'missed') {
          missedCount++;
        } else if (med.status == 'pending' && nextPending == null) {
          nextPending = med;
        }
      }

      setState(() {
        _medicines = list;
        _nextPendingMedicine = nextPending;
        _adherencePercent = list.isEmpty
            ? 100
            : ((takenCount / list.length) * 100).round();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Marks a medicine as taken, logs it in consumption history, and reloads state.
  Future<void> _markAsTaken(MedicineModel medicine) async {
    // 1. Update medicine status to 'taken' in medicines table
    final updatedMed = MedicineModel(
      id: medicine.id,
      medicineName: medicine.medicineName,
      dose: medicine.dose,
      scheduleTime: medicine.scheduleTime,
      status: 'taken',
    );
    await _medicineRepo.updateMedicine(updatedMed);

    // 2. Add record to history table
    final now = DateTime.now();
    final history = HistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: medicine.medicineName,
      takenAt: now,
      status: 'taken',
    );
    await _historyRepo.addHistory(history);

    // 3. Reload state
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicine.medicineName} berhasil diminum!'),
        backgroundColor: AppColors.wellnessGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Formats the current date in Indonesian layout.
  String _getFormattedDate() {
    final now = DateTime.now();
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Pagi';
    } else if (hour < 18) {
      return 'Siang';
    } else {
      return 'Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.medicalBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              const SizedBox(height: 8.0),
              Text(
                'Selamat ${_getGreeting()}, ${PreferenceHandler.userName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                _getFormattedDate(),
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 20.0),

              // Adherence Progress Section
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: AppColors.outlineVariant.withAlpha(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kepatuhan Hari Ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _adherencePercent == 100
                                ? 'Luar biasa, semua obat diminum!'
                                : 'Bagus, mari minum obat tepat waktu!',
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    // Progress Circle
                    SizedBox(
                      width: 64.0,
                      height: 64.0,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              width: 56.0,
                              height: 56.0,
                              child: CircularProgressIndicator(
                                value: _adherencePercent / 100.0,
                                backgroundColor: AppColors.outlineVariant
                                    .withAlpha(60),
                                color: AppColors.wellnessGreen,
                                strokeWidth: 5.5,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              '$_adherencePercent%',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.0,
                                color: AppColors.wellnessGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Today's Schedule Card (Next Reminder)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jadwal Terdekat',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(
                      color: AppColors.medicalBlue,
                    ),
                  ),
                )
              else if (_medicines.isEmpty)
                _buildNoMedicinesCard()
              else if (_nextPendingMedicine == null)
                _buildAllTakenCard()
              else
                _buildPendingMedCard(_nextPendingMedicine!),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Card displayed when no medicines are added yet.
  Widget _buildNoMedicinesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(100)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 40.0,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 12.0),
          Text(
            'Belum Ada Jadwal Obat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Silakan tambahkan jadwal obat Anda terlebih dahulu di menu Meds.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.0, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: widget.onAddMedTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.medicalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Tambah Obat'),
          ),
        ],
      ),
    );
  }

  /// Card displayed when all scheduled medicines are marked as taken.
  Widget _buildAllTakenCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 44.0,
            color: AppColors.wellnessGreen,
          ),
          const SizedBox(height: 12.0),
          Text(
            'Semua Obat Hari Ini Selesai!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Luar biasa! Anda telah meminum semua obat terjadwal Anda untuk hari ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.0, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  /// Card displaying details of the next scheduled pending medicine.
  Widget _buildPendingMedCard(MedicineModel medicine) {
    final parts = medicine.dose.split(' • ');
    final isOldFormat = parts.length >= 4;

    final dosage = parts.isNotEmpty ? parts[0] : medicine.dose;
    final form = isOldFormat ? parts[1] : '';
    final relation = isOldFormat ? parts[2] : (parts.length > 1 ? parts[1] : '');

    IconData icon = Icons.medication_rounded;
    final checkText = (form.isNotEmpty ? form : dosage).toLowerCase();
    if (checkText.contains('kapsul')) {
      icon = Icons.healing_rounded;
    } else if (checkText.contains('sirup') || checkText.contains('sendok') || checkText.contains('ml')) {
      icon = Icons.vaccines_rounded;
    }

    final doseInfo = isOldFormat
        ? '$dosage${form.isNotEmpty ? ' • 1 $form' : ''}${relation.isNotEmpty ? ' • $relation' : ''}'
        : '$dosage${relation.isNotEmpty ? ' • $relation' : ''}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.medicalBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.medicalBlue.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.surfaceWhite, size: 28.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.medicineName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surfaceWhite,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Dosis: $doseInfo',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.surfaceWhite.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16.0,
                      color: AppColors.surfaceWhite,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      medicine.scheduleTime,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surfaceWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsTaken(medicine),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceWhite,
                      foregroundColor: AppColors.medicalBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      'Tandai Sudah Diminum',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
