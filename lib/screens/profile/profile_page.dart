import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:aplikasi/screens/auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Profile Header Section
            const SizedBox(height: 16.0),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 110.0,
                        height: 110.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.outlineVariant.withAlpha(80),
                          border: Border.all(
                            color: AppColors.surfaceWhite,
                            width: 4.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 64.0,
                            color: AppColors.medicalBlue,
                          ),
                        ),
                      ),
                      // Edit Avatar FAB
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: AppColors.medicalBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 2.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.surfaceWhite,
                            size: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Budi Santoso',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'budi.santoso@email.com',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7ED),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 16.0,
                          color: AppColors.wellnessGreen,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'AKUN TERVERIFIKASI',
                          style: GoogleFonts.inter(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.wellnessGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),

            // Settings Options List
            _buildSettingCard(
              'Data Diri',
              'Informasi pribadi dan rekam medis',
              Icons.person_outline_rounded,
              AppColors.medicalBlue,
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Hubungkan Keluarga',
              'Pantau jadwal bersama anggota keluarga',
              Icons.family_restroom_rounded,
              const Color(0xFF934700),
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Pengaturan Notifikasi',
              'Atur pengingat obat dan alarm',
              Icons.notifications_active_outlined,
              AppColors.wellnessGreen,
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Kontak Darurat',
              'Nomor penting dan dokter keluarga',
              Icons.emergency_outlined,
              const Color(0xFFEB5757),
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Pusat Bantuan',
              'FAQ dan panduan penggunaan aplikasi',
              Icons.help_center_outlined,
              AppColors.textGrey,
            ),
            const SizedBox(height: 28.0),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52.0,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB5757),
                  foregroundColor: AppColors.surfaceWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20.0),
                label: Text(
                  'Keluar',
                  style: GoogleFonts.inter(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Option action
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 24.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGrey,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
