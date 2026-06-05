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
  bool _obatTaken = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            const SizedBox(height: 8.0),
            Text(
              'Selamat Pagi, Budi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              'Senin, 24 Oktober 2023',
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
                          _obatTaken
                              ? 'Luar biasa, semua obat diminum!'
                              : 'Bagus, terus pertahankan!',
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
                              value: _obatTaken ? 1.0 : 0.80,
                              backgroundColor: AppColors.outlineVariant
                                  .withAlpha(60),
                              color: AppColors.wellnessGreen,
                              strokeWidth: 5.5,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            _obatTaken ? '100%' : '80%',
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
                if (!_obatTaken)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withAlpha(40),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14.0,
                          color: AppColors.medicalBlue,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Dalam 45 mnt',
                          style: GoogleFonts.inter(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.medicalBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Medication card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _obatTaken
                    ? AppColors.surfaceWhite
                    : AppColors.medicalBlue,
                borderRadius: BorderRadius.circular(16.0),
                border: _obatTaken
                    ? Border.all(color: AppColors.outlineVariant.withAlpha(100))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _obatTaken
                        ? Colors.black.withAlpha(5)
                        : AppColors.medicalBlue.withAlpha(60),
                    blurRadius: 16.0,
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
                      color: _obatTaken
                          ? AppColors.wellnessGreen.withAlpha(25)
                          : AppColors.surfaceWhite.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _obatTaken
                          ? Icons.check_circle_rounded
                          : Icons.medication_rounded,
                      color: _obatTaken
                          ? AppColors.wellnessGreen
                          : AppColors.surfaceWhite,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amlodipine',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: _obatTaken
                                ? AppColors.textDark
                                : AppColors.surfaceWhite,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Dosis: 10 mg • 1 Tablet Sesudah Makan',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: _obatTaken
                                ? AppColors.textGrey
                                : AppColors.surfaceWhite.withAlpha(200),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16.0,
                              color: _obatTaken
                                  ? AppColors.textGrey
                                  : AppColors.surfaceWhite.withAlpha(200),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              '08:00 Pagi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: _obatTaken
                                    ? AppColors.textDark
                                    : AppColors.surfaceWhite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        if (!_obatTaken)
                          SizedBox(
                            width: double.infinity,
                            height: 48.0,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _obatTaken = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Obat ditandai sudah diminum!',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceWhite,
                                foregroundColor: AppColors.medicalBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                              label: Text(
                                'Tandai Sudah Diminum',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                          )
                        else
                          Text(
                            'Sudah diminum pukul 08:05 Pagi',
                            style: GoogleFonts.inter(
                              color: AppColors.wellnessGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
