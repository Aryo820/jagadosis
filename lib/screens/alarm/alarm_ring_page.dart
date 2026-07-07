import 'package:alarm/alarm.dart';
import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/history_model.dart';
import 'package:aplikasi/repositories/history_repository.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/services/alarm_service.dart';
import 'package:aplikasi/services/medicine_events.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen ringing UI shown when a medication alarm fires, styled like a
/// phone alarm clock. Reached via the Alarm.ringing listener in main.dart.
class AlarmRingPage extends StatelessWidget {
  const AlarmRingPage({super.key, required this.settings});

  /// The alarm that is currently ringing. Carries the medicine name and time in
  /// its notification title/body.
  final AlarmSettings settings;

  Future<void> _stop(BuildContext context) async {
    // Resolve which medicine + dose slot rang, then mark it taken and log it —
    // mirrors _markSlotAsTaken in home_page.dart so the dashboard and history
    // stay consistent whether the dose is confirmed from the alarm or the app.
    final resolved = await AlarmService().resolveSlot(settings.id);
    if (resolved != null) {
      final updated = resolved.medicine.copyWithSlotStatus(
        resolved.timeIndex,
        'taken',
      );
      await MedicineRepository().updateMedicine(updated);

      final now = DateTime.now();
      await HistoryRepository().addHistory(
        HistoryModel(
          id: '${now.millisecondsSinceEpoch}_${resolved.medicine.id}_${resolved.timeIndex}',
          medicineName: resolved.medicine.medicineName,
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
      await Alarm.stop(settings.id);
      await AlarmService().scheduleForMedicine(updated);
    } else {
      // Medicine was deleted while ringing: just stop. Any stray alarm is
      // cleared by the next rescheduleAll (startup/resume).
      await Alarm.stop(settings.id);
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze(BuildContext context) async {
    final minutes = PreferenceHandler.notificationSnooze;
    await AlarmService().snooze(settings, Duration(minutes: minutes));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = settings.notificationSettings.title;
    final body = settings.notificationSettings.body;
    final snoozeMinutes = PreferenceHandler.notificationSnooze;

    // Block the hardware back button: the alarm must be stopped or snoozed via
    // the buttons, never dismissed silently while still ringing.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.medicalBlue,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medication_liquid_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withAlpha(220),
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 3),
                // Snooze
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _snooze(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.snooze_rounded),
                    label: Text(
                      'Tunda $snoozeMinutes Menit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stop
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _stop(context),
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
                      'Sudah Diminum',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
