import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Pusat Bantuan',
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
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.medicalBlue,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.medicalBlue.withAlpha(50),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ada yang bisa kami bantu?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Temukan jawaban atas pertanyaan umum seputar penggunaan aplikasi JagaDosis di bawah ini.',
                    style: GoogleFonts.inter(
                      fontSize: 13.0,
                      color: AppColors.surfaceWhite.withAlpha(220),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),
            
            Text(
              'Pertanyaan Sering Diajukan (FAQ)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12.0),
            
            _buildFaqTile(
              question: 'Bagaimana cara menambah jadwal obat baru?',
              answer: 'Anda dapat membuka tab "Obat" (ikon ketiga di bar navigasi bawah), lalu ketuk tombol "+ Tambah Obat" di sudut kanan bawah. Isi nama obat, dosis, frekuensi harian, hubungan dengan makanan, dan atur jam pengingat sebelum menyimpan.',
              icon: Icons.add_moderator_rounded,
            ),
            const SizedBox(height: 12.0),
            
            _buildFaqTile(
              question: 'Mengapa saya tidak menerima notifikasi pengingat?',
              answer: 'Pastikan Anda telah mengizinkan notifikasi untuk JagaDosis di pengaturan HP Anda. Pada perangkat Android tertentu (terutama Xiaomi, Oppo, Vivo, Realme), Anda juga harus mengizinkan fitur "Mulai Otomatis" (Auto-start) dan menonaktifkan "Optimasi Baterai" (Battery Optimization) agar sistem tidak menghentikan aplikasi secara paksa.',
              icon: Icons.notifications_off_outlined,
            ),
            const SizedBox(height: 12.0),
            
            _buildFaqTile(
              question: 'Apakah data medis saya aman di aplikasi ini?',
              answer: 'Sangat aman. JagaDosis dirancang offline-first, artinya seluruh informasi profil, jadwal obat, riwayat konsumsi, dan kontak darurat Anda disimpan secara lokal di dalam penyimpanan terenkripsi HP Anda sendiri tanpa diunggah ke server mana pun.',
              icon: Icons.security_rounded,
            ),
            const SizedBox(height: 12.0),
            
            _buildFaqTile(
              question: 'Bagaimana cara memantau kepatuhan minum obat?',
              answer: 'Di halaman "Beranda", Anda dapat melihat persentase kepatuhan harian secara langsung dalam bentuk diagram lingkaran. Untuk analisis yang lebih mendalam, buka tab "Riwayat" untuk melihat catatan lengkap konsumsi obat Anda secara mingguan, bulanan, maupun tahunan.',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 12.0),
            
            _buildFaqTile(
              question: 'Bagaimana cara menggunakan Kontak Darurat?',
              answer: 'Buka menu "Kontak Darurat" di profil Anda, lalu tambahkan kontak penting seperti keluarga dekat atau nomor klinik/dokter Anda. Kontak tersebut dapat dihubungi secara instan dengan menekan tombol telepon pada kartu kontak tersebut saat situasi mendesak.',
              icon: Icons.contact_emergency_outlined,
            ),
            const SizedBox(height: 32.0),
            
            // Footer Version
            Center(
              child: Text(
                'JagaDosis v1.0.0 • Offline-First Medication Companion',
                style: GoogleFonts.inter(
                  fontSize: 11.0,
                  color: AppColors.textGrey.withAlpha(150),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile({
    required String question,
    required String answer,
    required IconData icon,
  }) {
    return Container(
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
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.backgroundBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.medicalBlue, size: 20),
          ),
          title: Text(
            question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          iconColor: AppColors.medicalBlue,
          collapsedIconColor: AppColors.textGrey,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0, top: 4.0),
              child: Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
