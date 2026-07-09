import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/history_model.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/history_repository.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/services/auth_service.dart';
import 'package:aplikasi/services/medicine_events.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:aplikasi/utils/email_verification_guard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single scheduled dose: one medicine at one of its scheduled times.
/// A medicine taken twice a day produces two [_DoseSlot]s, each with its own
/// status so they can be taken/missed independently.
class _DoseSlot {
  final MedicineModel medicine;
  final int timeIndex;
  final String time; // "HH:mm"
  final String status;

  _DoseSlot({
    required this.medicine,
    required this.timeIndex,
    required this.time,
    required this.status,
  });

  /// Minutes since midnight for this slot's time, or null if unparseable.
  int? get minutesOfDay {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}

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
  final AuthService _authService = AuthService();

  List<MedicineModel> _medicines = [];
  bool _isLoading = true;
  _DoseSlot? _nextPendingSlot;
  int _adherencePercent = 0;
  bool _emailVerified = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshVerificationStatus();
    // Reload when a dose is confirmed elsewhere (e.g. the alarm ring screen) so
    // the schedule updates without needing a bottom-nav tab switch.
    medicineDataRevision.addListener(_onMedicineDataChanged);
  }

  @override
  void dispose() {
    medicineDataRevision.removeListener(_onMedicineDataChanged);
    super.dispose();
  }

  void _onMedicineDataChanged() {
    if (mounted) _loadData();
  }

  /// Refreshes the account's verification status from the server so the banner
  /// disappears on the next home visit once the user has clicked the link.
  Future<void> _refreshVerificationStatus() async {
    try {
      await _authService.reloadCurrentUser();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _emailVerified = _authService.isEmailVerified);
  }

  /// Returns true if the dose slot at the given "HH:mm" time should be marked
  /// as 'missed': its time already passed today AND it was due *after* the
  /// medicine was created. A medicine added after today's slot time is not
  /// instantly marked missed — it simply starts from its next occurrence.
  bool _shouldMarkMissed(String hhmm, DateTime createdAt) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;

    final now = DateTime.now();
    final slotToday = DateTime(now.year, now.month, now.day, hour, minute);

    return slotToday.isBefore(now) && !slotToday.isBefore(createdAt);
  }

  /// Flattens medicines into individual dose slots (one per scheduled time).
  List<_DoseSlot> _buildSlots(List<MedicineModel> medicines) {
    final slots = <_DoseSlot>[];
    for (final med in medicines) {
      final times = med.scheduleTimes;
      final statuses = med.slotStatuses;
      for (int i = 0; i < times.length; i++) {
        slots.add(
          _DoseSlot(
            medicine: med,
            timeIndex: i,
            time: times[i],
            status: i < statuses.length ? statuses[i] : 'pending',
          ),
        );
      }
    }
    return slots;
  }

  /// Checks every pending dose slot and marks it as 'missed' if its scheduled
  /// time has already passed. Each medicine is updated once (preserving the
  /// status of its other slots) and one history entry is added per missed slot.
  Future<void> _checkAndMarkMissed(List<MedicineModel> medicines) async {
    for (final med in medicines) {
      final statuses = med.slotStatuses;
      final times = med.scheduleTimes;
      bool changed = false;

      for (int i = 0; i < times.length; i++) {
        if (statuses[i] == 'pending' &&
            _shouldMarkMissed(times[i], med.createdAt)) {
          statuses[i] = 'missed';
          changed = true;

          // Ambil jam dan menit dari jadwal obat
          final parts = times[i].split(':');
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;

          final now = DateTime.now();
          // Buat tanggal dan jam sesuai jadwal obat yang terlewat
          final scheduleTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          final history = HistoryModel(
            id: '${now.millisecondsSinceEpoch}_${med.id}_$i',
            medicineName: med.medicineName,
            takenAt: scheduleTime, // Gunakan waktu jadwal, bukan DateTime.now()
            status: 'missed',
          );
          await _historyRepo.addHistory(history);
        }
      }

      if (changed) {
        await _medicineRepo.updateMedicine(
          med.copyWith(status: MedicineModel.joinStatuses(statuses)),
        );
      }
    }
  }

  Future<List<MedicineModel>> _rollOverOldStatuses(
    List<MedicineModel> medicines,
  ) async {
    final today = MedicineModel.dateKey(DateTime.now());
    final todayDate = DateTime.tryParse(today);
    final updatedMedicines = <MedicineModel>[];

    for (final med in medicines) {
      if (med.statusDate == today) {
        updatedMedicines.add(med);
        continue;
      }

      final statusDate = DateTime.tryParse(med.statusDate);
      final shouldBackfillMissedHistory =
          statusDate != null &&
          todayDate != null &&
          statusDate.isBefore(todayDate) &&
          med.statusDate !=
              MedicineModel.dateKey(DateTime.fromMillisecondsSinceEpoch(0));
      final times = med.scheduleTimes;
      final statuses = med.slotStatuses;

      // Non-null only when a backfill is warranted; the null-check below both
      // skips non-backfill cases and promotes the date for use as DateTime.
      final backfillDate = shouldBackfillMissedHistory ? statusDate : null;

      for (int i = 0; i < times.length; i++) {
        if (statuses[i] != 'pending' || backfillDate == null) {
          continue;
        }

        final parts = times[i].split(':');
        if (parts.length != 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final missedAt = DateTime(
          backfillDate.year,
          backfillDate.month,
          backfillDate.day,
          hour,
          minute,
        );
        if (missedAt.isBefore(med.createdAt)) continue;

        final history = HistoryModel(
          id: '${missedAt.millisecondsSinceEpoch}_${med.id}_$i',
          medicineName: med.medicineName,
          takenAt: missedAt,
          status: 'missed',
        );
        await _historyRepo.addHistory(history);
      }

      final resetMedicine = med.resetDailyStatus();
      await _medicineRepo.updateMedicine(resetMedicine);
      updatedMedicines.add(resetMedicine);
    }

    return updatedMedicines;
  }

  /// Refreshes lists, calculates adherence progress, and determines the next
  /// pending dose slot (earliest still-pending scheduled time).
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // First pass: detect and mark any overdue pending dose slots as missed
      final rawList = await _medicineRepo.getAllMedicines();
      final todayList = await _rollOverOldStatuses(rawList);
      await _checkAndMarkMissed(todayList);

      // Re-fetch after possible status changes
      final list = await _medicineRepo.getAllMedicines();

      // Expand into individual dose slots so each scheduled time is tracked.
      final slots = _buildSlots(list);

      int takenCount = 0;
      _DoseSlot? nextPending;

      for (final slot in slots) {
        if (slot.status == 'taken') {
          takenCount++;
        } else if (slot.status == 'pending') {
          // Pick the earliest pending slot by time of day.
          if (nextPending == null ||
              (slot.minutesOfDay ?? 0) < (nextPending.minutesOfDay ?? 0)) {
            nextPending = slot;
          }
        }
      }

      // Adherence is the share of *all* of today's scheduled doses that have
      // been taken. A dose that hasn't been marked taken yet — whether still
      // pending or already missed — counts against the total, so the figure
      // starts at 0% when a medicine is added and only rises once the user
      // confirms "sudah diminum". With no doses scheduled at all it is 0%.
      final int totalCount = slots.length;

      setState(() {
        _medicines = list;
        _nextPendingSlot = nextPending;
        _adherencePercent = totalCount == 0
            ? 0
            : ((takenCount / totalCount) * 100).round();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Marks a single dose slot as taken, logs it in consumption history, and
  /// reloads state. Other scheduled times of the same medicine are untouched.
  Future<void> _markSlotAsTaken(_DoseSlot slot) async {
    // 1. Update only this slot's status, preserving the rest.
    final updatedMed = slot.medicine.copyWithSlotStatus(
      slot.timeIndex,
      'taken',
    );
    await _medicineRepo.updateMedicine(updatedMed);

    // 2. Add record to history table.
    final now = DateTime.now();
    final history = HistoryModel(
      id: '${now.millisecondsSinceEpoch}_${slot.medicine.id}_${slot.timeIndex}',
      medicineName: slot.medicine.medicineName,
      takenAt: now,
      status: 'taken',
    );
    await _historyRepo.addHistory(history);

    // 3. Reload state
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${slot.medicine.medicineName} (${slot.time}) berhasil diminum!',
        ),
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
        onRefresh: () async {
          await _loadData();
          await _refreshVerificationStatus();
        },
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

              // Email verification banner — only while the account is unverified.
              if (!_emailVerified) ...[
                _buildVerificationBanner(),
                const SizedBox(height: 20.0),
              ],

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
                                ? 'Kepatuhan Anda sempurna hari ini!'
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
              else if (_nextPendingSlot == null)
                _buildAllTakenCard()
              else
                _buildPendingMedCard(_nextPendingSlot!),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Warning banner shown on the home screen while the account's email is not
  /// yet verified. Explains why some features are locked and offers a one-tap
  /// resend plus a way to re-check status after verifying in the browser.
  Widget _buildVerificationBanner() {
    const amber = Color(0xFF934700);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: amber.withAlpha(20),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: amber.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: amber,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Email belum diverifikasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            'Verifikasi email Anda untuk membuka fitur tambah/ubah obat dan '
            'melengkapi data diri. Cek kotak masuk & folder spam.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      EmailVerificationGuard.resendVerificationEmail(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: amber,
                    side: const BorderSide(color: amber),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Kirim Ulang',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _refreshVerificationStatus();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _emailVerified
                              ? 'Email terverifikasi. Semua fitur terbuka!'
                              : 'Belum terverifikasi. Klik link di email Anda dulu.',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: _emailVerified
                            ? AppColors.wellnessGreen
                            : Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amber,
                    foregroundColor: AppColors.surfaceWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Saya Sudah Verifikasi',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  /// Card displaying details of the next scheduled pending dose slot.
  Widget _buildPendingMedCard(_DoseSlot slot) {
    final medicine = slot.medicine;
    final parts = medicine.dose.split(' • ');
    final isOldFormat = parts.length >= 4;

    final dosage = parts.isNotEmpty ? parts[0] : medicine.dose;
    final form = isOldFormat ? parts[1] : '';
    final relation = isOldFormat
        ? parts[2]
        : (parts.length > 1 ? parts[1] : '');

    IconData icon = Icons.medication_rounded;
    final checkText = (form.isNotEmpty ? form : dosage).toLowerCase();
    if (checkText.contains('kapsul')) {
      icon = Icons.healing_rounded;
    } else if (checkText.contains('sirup') ||
        checkText.contains('sendok') ||
        checkText.contains('ml')) {
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
                      slot.time,
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
                    onPressed: () => _markSlotAsTaken(slot),
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
