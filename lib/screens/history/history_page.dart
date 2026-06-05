import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aplikasi/utils/app_colors.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adherence summary card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kepatuhan Mingguan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Kerja bagus minggu ini!',
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '92% ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.medicalBlue,
                              ),
                            ),
                            TextSpan(
                              text: 'Diminum tepat waktu',
                              style: GoogleFonts.inter(
                                fontSize: 12.0,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Progress indicator circular
                  SizedBox(
                    width: 56.0,
                    height: 56.0,
                    child: Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: CircularProgressIndicator(
                              value: 0.92,
                              backgroundColor: AppColors.outlineVariant.withAlpha(60),
                              color: AppColors.wellnessGreen,
                              strokeWidth: 5.0,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '92%',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
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

            // Horizontal calendar section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Oktober 2023',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today_rounded, size: 16.0),
                  label: Text(
                    'Hari Ini',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.medicalBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Calendar Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCalendarDay('Sen', '16', isCompleted: true),
                  _buildCalendarDay('Sel', '17', isCompleted: true),
                  _buildCalendarDay('Rab', '18', isActive: true, isCompleted: true),
                  _buildCalendarDay('Kam', '19', isMissed: true),
                  _buildCalendarDay('Jum', '20', isFuture: true),
                  _buildCalendarDay('Sab', '21', isFuture: true),
                  _buildCalendarDay('Min', '22', isFuture: true),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Daily Log Section
            Text(
              'Rabu, 18 Oktober',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16.0),

            // Morning Group
            _buildTimeGroupHeader('Pagi', Icons.wb_sunny_rounded, const Color(0xFFE65100)),
            const SizedBox(height: 8.0),
            _buildLogCard(
              'Amlodipine',
              '1 Tablet • 5mg',
              'Diminum',
              '08:05 Pagi',
              AppColors.wellnessGreen,
              Icons.check_circle_rounded,
            ),
            const SizedBox(height: 8.0),
            _buildLogCard(
              'Metformin',
              '1 Tablet • 500mg',
              'Diminum',
              '08:10 Pagi',
              AppColors.wellnessGreen,
              Icons.check_circle_rounded,
            ),
            const SizedBox(height: 16.0),

            // Afternoon Group
            _buildTimeGroupHeader('Siang', Icons.wb_cloudy_rounded, AppColors.medicalBlue),
            const SizedBox(height: 8.0),
            _buildLogCard(
              'Vitamin D3',
              '1 Kapsul • 1000 IU',
              'Terlewat',
              '01:00 Siang',
              const Color(0xFFEB5757),
              Icons.cancel_rounded,
            ),
            const SizedBox(height: 16.0),

            // Night Group
            _buildTimeGroupHeader('Malam', Icons.bedtime_rounded, AppColors.textGrey),
            const SizedBox(height: 8.0),
            _buildLogCard(
              'Simvastatin',
              '1 Tablet • 20mg',
              'Mendatang',
              '08:00 Malam',
              AppColors.textGrey,
              Icons.schedule_rounded,
              isFuture: true,
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(String dayName, String dayNumber,
      {bool isActive = false, bool isCompleted = false, bool isMissed = false, bool isFuture = false}) {
    Color bg = AppColors.surfaceWhite;
    Color textColor = AppColors.textDark;
    Color subColor = AppColors.textGrey;

    if (isActive) {
      bg = AppColors.medicalBlue;
      textColor = AppColors.surfaceWhite;
      subColor = AppColors.surfaceWhite.withAlpha(200);
    } else if (isFuture) {
      textColor = AppColors.textDark.withAlpha(120);
      subColor = AppColors.textGrey.withAlpha(120);
    }

    return Container(
      width: 56.0,
      height: 72.0,
      margin: const EdgeInsets.only(right: 10.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive ? AppColors.medicalBlue : AppColors.outlineVariant.withAlpha(100),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.medicalBlue.withAlpha(60),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: GoogleFonts.inter(
              fontSize: 11.0,
              fontWeight: FontWeight.w500,
              color: subColor,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            dayNumber,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4.0),
          if (isCompleted)
            Container(
              width: 5.0,
              height: 5.0,
              decoration: const BoxDecoration(
                color: AppColors.wellnessGreen,
                shape: BoxShape.circle,
              ),
            )
          else if (isMissed)
            Container(
              width: 5.0,
              height: 5.0,
              decoration: const BoxDecoration(
                color: Color(0xFFEB5757),
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 5.0),
        ],
      ),
    );
  }

  Widget _buildTimeGroupHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18.0),
        const SizedBox(width: 6.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(String title, String dosage, String status, String time, Color color, IconData icon,
      {bool isFuture = false}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: isFuture ? AppColors.textDark.withAlpha(150) : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  dosage,
                  style: GoogleFonts.inter(
                    fontSize: 12.0,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  color: color,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 11.0,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
