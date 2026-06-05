import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aplikasi/utils/app_colors.dart';

class MedsPage extends StatelessWidget {
  const MedsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Obat Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '3 OBAT',
                    style: GoogleFonts.inter(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medicalBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Med Card 1
            _buildMedCard(
              context,
              'Amlodipine',
              '10 mg • 1 Tablet',
              '1x Sehari • Sesudah Makan',
              'Sisa obat: 12 tablet',
              Icons.medication_rounded,
              AppColors.medicalBlue,
              pillsRemaining: 12,
            ),
            const SizedBox(height: 12.0),

            // Med Card 2
            _buildMedCard(
              context,
              'Metformin',
              '500 mg • 1 Tablet',
              '2x Sehari • Bersama Makanan',
              'Sisa obat: 24 tablet',
              Icons.healing_rounded,
              AppColors.wellnessGreen,
              pillsRemaining: 24,
            ),
            const SizedBox(height: 12.0),

            // Med Card 3
            _buildMedCard(
              context,
              'Vitamin D3',
              '1000 IU • 1 Kapsul',
              '1x Sehari • Pagi Hari',
              'Sisa obat: 5 kapsul (Hampir Habis!)',
              Icons.vaccines_rounded,
              const Color(0xFF934700),
              pillsRemaining: 5,
              hasWarning: true,
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Action to add medication
        },
        backgroundColor: AppColors.medicalBlue,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Tambah Obat',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMedCard(
    BuildContext context,
    String name,
    String dosage,
    String instructions,
    String remainingStock,
    IconData icon,
    Color color, {
    required int pillsRemaining,
    bool hasWarning = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: hasWarning ? const Color(0xFFEB5757).withAlpha(100) : AppColors.outlineVariant.withAlpha(50),
          width: hasWarning ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24.0,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    dosage,
                    style: GoogleFonts.inter(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    instructions,
                    style: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Icon(
                        hasWarning ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                        size: 14.0,
                        color: hasWarning ? const Color(0xFFEB5757) : AppColors.textGrey,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        remainingStock,
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          fontWeight: hasWarning ? FontWeight.bold : FontWeight.normal,
                          color: hasWarning ? const Color(0xFFEB5757) : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textGrey),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
