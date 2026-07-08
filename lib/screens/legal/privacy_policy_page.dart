import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The version of the privacy policy currently shown to users. Bump this
/// whenever the policy text below changes materially — the value is recorded
/// against each account at registration (see [ProfileService.createInitial]),
/// so a change here lets us tell who agreed to which version.
const String privacyPolicyVersion = '1.0';

/// A read-only, in-app rendering of JagaDosis' privacy policy. Opened from the
/// consent checkbox on the registration screen. The copy below is a starting
/// point meant to be reviewed/replaced by the real legal text.
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
