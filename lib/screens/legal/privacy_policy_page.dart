import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Versi kebijakan privasi yang saat ini ditampilkan kepada pengguna. Naikkan
/// nilai ini setiap kali teks kebijakan di bawah berubah secara signifikan —
/// nilainya dicatat pada tiap akun saat registrasi (lihat
/// [ProfileService.createInitial]), sehingga perubahan di sini memungkinkan kita
/// mengetahui siapa yang menyetujui versi yang mana.
const String privacyPolicyVersion = '1.0';

/// Tampilan kebijakan privasi JagaDosis di dalam aplikasi yang bersifat
/// baca-saja. Dibuka dari kotak centang persetujuan pada layar registrasi. Teks
/// di bawah hanyalah titik awal yang dimaksudkan untuk ditinjau/diganti dengan
/// teks hukum yang sebenarnya.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Kebijakan Privasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kebijakan Privasi JagaDosis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Versi $privacyPolicyVersion',
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24.0),

              _Section(
                title: '1. Data yang Kami Kumpulkan',
                body:
                    'Kami mengumpulkan data yang Anda berikan secara langsung, '
                    'yaitu nama, alamat email, serta data kesehatan seperti '
                    'daftar obat, jadwal dosis, riwayat konsumsi, golongan '
                    'darah, alergi, dan kontak darurat.',
              ),
              _Section(
                title: '2. Penggunaan Data',
                body:
                    'Data Anda digunakan semata-mata untuk menjalankan fungsi '
                    'aplikasi: mengingatkan jadwal minum obat, menyimpan '
                    'riwayat, dan menampilkan informasi kesehatan Anda. Kami '
                    'tidak menjual data Anda kepada pihak ketiga.',
              ),
              _Section(
                title: '3. Penyimpanan & Keamanan',
                body:
                    'Data disimpan pada layanan Google Firebase dan hanya dapat '
                    'diakses oleh akun Anda sendiri. Akses dilindungi oleh '
                    'autentikasi dan aturan keamanan server.',
              ),
              _Section(
                title: '4. Data Kesehatan (Data Spesifik)',
                body:
                    'Data kesehatan tergolong data pribadi yang bersifat '
                    'spesifik. Dengan menyetujui kebijakan ini, Anda memberikan '
                    'persetujuan atas pemrosesan data tersebut untuk keperluan '
                    'aplikasi sesuai UU Pelindungan Data Pribadi.',
              ),
              _Section(
                title: '5. Hak Anda',
                body:
                    'Anda berhak mengakses, memperbarui, dan menghapus data '
                    'pribadi Anda kapan saja melalui halaman profil, atau '
                    'dengan menghubungi kami.',
              ),
              _Section(
                title: '6. Perubahan Kebijakan',
                body:
                    'Kebijakan ini dapat diperbarui dari waktu ke waktu. '
                    'Perubahan penting akan diberitahukan melalui aplikasi.',
              ),

              const SizedBox(height: 8.0),
              Text(
                'Dengan mendaftar, Anda menyatakan telah membaca dan menyetujui '
                'kebijakan privasi ini.',
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 14.0,
              height: 1.5,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
