import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/history_model.dart';
import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/history_repository.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/services/alarm_service.dart';
import 'package:aplikasi/services/medicine_events.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen ringing UI shown when a medication alarm fires. Styled like the
/// JagaDosis design mockup: a light, card-based layout showing the medicine's
/// real name, dose and time (resolved from the ringing alarm's id), with a
/// pulsing bell and a success overlay after the dose is confirmed.
///
/// Reached via the Alarm.ringing listener in main.dart. Silent dismissal is
/// blocked (see [PopScope] below): a ringing dose can only be resolved by
/// "Sudah Minum" or "Tunda", never swiped away.
class AlarmRingPage extends StatefulWidget {
  const AlarmRingPage({super.key, required this.settings});

  /// The alarm that is currently ringing. Carries the medicine name and time in
  /// its notification title/body, used as a fallback when the medicine can no
  /// longer be resolved (e.g. it was deleted while ringing).
  final AlarmSettings settings;

  @override
  State<AlarmRingPage> createState() => _AlarmRingPageState();
}

class _AlarmRingPageState extends State<AlarmRingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  /// How long the alarm rings before it gives up: it auto-stops and the dose is
  /// marked 'missed' so an unanswered alarm can't loop forever.
  static const Duration _autoStopAfter = Duration(minutes: 1);

  /// Resolved dose behind this ring, or null while loading / if unresolvable.
  MedicineModel? _medicine;
  int _timeIndex = 0;
  bool _resolved = false;

  /// True once the dose has been confirmed; drives the success overlay.
  bool _taken = false;

  /// Guards the three terminal actions (taken / snooze / auto-miss) so a manual
  /// tap landing at the same instant the auto-stop timer fires runs only once.
  bool _finalizing = false;

  /// Ticks down the auto-stop countdown once a second; fires the auto-miss when
  /// it reaches zero. Cancelled as soon as the user acts or the page closes.
  Timer? _autoStopTimer;
  int _remainingSeconds = _autoStopAfter.inSeconds;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _resolveDose();
    _startAutoStopCountdown();
  }

  /// Starts the one-per-second countdown that auto-stops the ring when it hits
  /// zero, marking the dose as missed.
  void _startAutoStopCountdown() {
    _autoStopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onAutoMissed();
      }
    });
  }

  /// Remaining auto-stop time as "m:ss" for the countdown hint.
  String get _countdownLabel {
    final s = _remainingSeconds.clamp(0, _autoStopAfter.inSeconds);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Resolves which medicine + dose slot rang so the card can show real data.
  /// On failure the UI falls back to the alarm's notification text.
  Future<void> _resolveDose() async {
    final resolved = await AlarmService().resolveSlot(widget.settings.id);
    if (!mounted) return;
    setState(() {
      _medicine = resolved?.medicine;
      _timeIndex = resolved?.timeIndex ?? 0;
      _resolved = true;
    });
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Confirms the dose: marks the slot taken, logs history, stops the ring and
  /// re-arms the medicine's next occurrences, then shows the success overlay.
  /// Mirrors _markSlotAsTaken in home_page.dart so the dashboard and history
  /// stay consistent whether a dose is confirmed from the alarm or the app.
  Future<void> _onTaken() async {
    if (_finalizing) return;
    _finalizing = true;
    _autoStopTimer?.cancel();

    final medicine = _medicine;
    if (medicine != null) {
      final updated = medicine.copyWithSlotStatus(_timeIndex, 'taken');
      await MedicineRepository().updateMedicine(updated);

      final now = DateTime.now();
      await HistoryRepository().addHistory(
        HistoryModel(
          id: '${now.millisecondsSinceEpoch}_${medicine.id}_$_timeIndex',
          medicineName: medicine.medicineName,
          takenAt: now,
          status: 'taken',
        ),
      );

      // Tell any open screen (e.g. HomePage's "jadwal terdekat") to refresh so
      // the dose disappears from the schedule immediately, without a tab switch.
      notifyMedicineDataChanged();

      // Stop the ring and re-arm this medicine's next occurrences from its real
      // schedule. Using the schedule (not ringing.dateTime + 1 day) keeps the
      // next day at the correct time even when the alarm was snoozed first.
      await Alarm.stop(widget.settings.id);
      await AlarmService().scheduleForMedicine(updated);
    } else {
      // Medicine was deleted while ringing: just stop. Any stray alarm is
      // cleared by the next rescheduleAll (startup/resume).
      await Alarm.stop(widget.settings.id);
    }

    if (mounted) setState(() => _taken = true);
  }

  Future<void> _onSnooze() async {
    if (_finalizing) return;
    _finalizing = true;
    _autoStopTimer?.cancel();

    final minutes = PreferenceHandler.notificationSnooze;
    await AlarmService().snooze(widget.settings, Duration(minutes: minutes));
    if (mounted) Navigator.of(context).pop();
  }

  /// Fired when the auto-stop countdown expires with no user action: silences
  /// the ring, records the dose as missed, re-arms tomorrow's alarm, and closes
  /// the screen. Mirrors [_onTaken] but writes a 'missed' status instead.
  Future<void> _onAutoMissed() async {
    if (_finalizing) return;
    _finalizing = true;
    _autoStopTimer?.cancel();

    final medicine = _medicine;
    if (medicine != null) {
      final updated = medicine.copyWithSlotStatus(_timeIndex, 'missed');
      await MedicineRepository().updateMedicine(updated);

      final now = DateTime.now();
      await HistoryRepository().addHistory(
        HistoryModel(
          id: '${now.millisecondsSinceEpoch}_${medicine.id}_$_timeIndex',
          medicineName: medicine.medicineName,
          takenAt: now,
          status: 'missed',
        ),
      );

      notifyMedicineDataChanged();

      await Alarm.stop(widget.settings.id);
      await AlarmService().scheduleForMedicine(updated);
    } else {
      await Alarm.stop(widget.settings.id);
    }

    if (mounted) Navigator.of(context).pop();
  }

  // --- Parsed dose fields, derived from the medicine's composite `dose` string.
  // Same parsing the home page uses:
  //   Old: "500 mg • Tablet • Sesudah Makan • 1x Sehari" (4 parts)
  //   New: "500 Tablet • Sesudah Makan • 1x Sehari"      (3 parts)

  List<String> get _doseParts => (_medicine?.dose ?? '').split(' • ');
  bool get _isOldFormat => _doseParts.length >= 4;

  String get _dosage =>
      _doseParts.isNotEmpty ? _doseParts.first : (_medicine?.dose ?? '');

  String get _form => _isOldFormat ? _doseParts[1] : '';

  String get _relation => _isOldFormat
      ? _doseParts[2]
      : (_doseParts.length > 1 ? _doseParts[1] : '');

  /// The dose time for this slot, e.g. "08:00". Falls back to the alarm's
  /// scheduled time when the medicine can't be resolved.
  String get _timeLabel {
    final times = _medicine?.scheduleTimes ?? const [];
    if (_timeIndex >= 0 && _timeIndex < times.length) return times[_timeIndex];
    final dt = widget.settings.dateTime;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Medicine name for the card; falls back to the notification title's payload.
  String get _medicineName =>
      _medicine?.medicineName ?? (_resolved ? 'Obat Anda' : '');

  /// Subtitle under the name: dosage + meal relation when available.
  String get _doseSubtitle {
    if (_medicine == null) return widget.settings.notificationSettings.body;
    final buffer = StringBuffer(_dosage);
    if (_relation.isNotEmpty) buffer.write(' • $_relation');
    return buffer.toString();
  }

  /// Value shown in the "Dosis" tile, e.g. "1 Tablet" or the raw dosage.
  String get _dosisValue => _form.isNotEmpty ? '1 $_form' : _dosage;

  IconData get _medIcon {
    final check = (_form.isNotEmpty ? _form : _dosage).toLowerCase();
    if (check.contains('kapsul')) return Icons.healing_rounded;
    if (check.contains('sirup') ||
        check.contains('sendok') ||
        check.contains('ml')) {
      return Icons.vaccines_rounded;
    }
    return Icons.medication_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final snoozeMinutes = PreferenceHandler.notificationSnooze;

    // Block the hardware back button: the alarm must be stopped or snoozed via
    // the buttons, never dismissed silently while still ringing.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundBlue, Color(0xFFE6E8F1)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                _buildContent(snoozeMinutes),
                if (_taken) _buildSuccessOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(int snoozeMinutes) {
    return Column(
      children: [
        // Brand header
        SizedBox(
          height: 64,
          child: Center(
            child: Text(
              'JagaDosis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.medicalBlue,
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                // Pulsing bell
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.06).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.medicalBlue.withAlpha(50),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.medicalBlue,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Waktunya Minum Obat!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.medicalBlue,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jangan lupa untuk menjaga kesehatan Anda hari ini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 28),
                _buildMedicineCard(),
                const SizedBox(height: 28),
                _buildActions(snoozeMinutes),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header stripe
          Container(height: 12, color: AppColors.medicalBlue),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(_medIcon, color: AppColors.medicalBlue, size: 36),
                ),
                const SizedBox(height: 16),
                if (!_resolved)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Text(
                    _medicineName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _doseSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.medication_rounded,
                        label: 'DOSIS',
                        value: _resolved && _dosisValue.isNotEmpty
                            ? _dosisValue
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.schedule_rounded,
                        label: 'WAKTU',
                        value: '$_timeLabel WIB',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.medicalBlue, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(int snoozeMinutes) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          // Primary: taken
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton.icon(
              onPressed: _onTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wellnessGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.wellnessGreen.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 28),
              label: Text(
                'Sudah Minum',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Secondary: snooze
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton.icon(
              onPressed: _onSnooze,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.medicalBlue,
                side: const BorderSide(color: AppColors.medicalBlue, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.snooze_rounded),
              label: Text(
                'Tunda $snoozeMinutes Menit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Menekan 'Sudah Minum' akan mencatat riwayat hari ini.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: AppColors.textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'Alarm berhenti otomatis dalam $_countdownLabel',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.backgroundBlue.withAlpha(245),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                color: AppColors.wellnessGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.done_all_rounded,
                color: Colors.white,
                size: 68,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hebat! Obat Diminum',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.medicalBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data Anda telah diperbarui. Tetap sehat bersama JagaDosis!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textGrey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medicalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Kembali ke Beranda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
