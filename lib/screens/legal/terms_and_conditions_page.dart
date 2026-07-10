import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Versi syarat & ketentuan yang saat ini ditampilkan kepada pengguna. Naikkan
/// nilai ini setiap kali isi ketentuan di bawah berubah secara signifikan —
/// nilainya dicatat pada tiap akun saat registrasi (lihat
/// [ProfileService.createInitial]), sehingga perubahan di sini memungkinkan kita
/// mengetahui siapa yang menyetujui versi yang mana.
const String termsVersion = '1.0';

/// Tampilan syarat & ketentuan JagaDosis di dalam aplikasi yang bersifat
/// baca-saja. Dibuka dari kotak centang persetujuan pada layar registrasi. Teks
/// di bawah hanyalah titik awal yang dimaksudkan untuk ditinjau/diganti dengan
/// teks hukum yang sebenarnya.
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Syarat & Ketentuan',
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
                'Syarat & Ketentuan JagaDosis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Versi $termsVersion',
                style: GoogleFonts.inter(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24.0),

              // Penyangkalan medis — ditonjolkan karena ini klausul paling
              // penting untuk aplikasi kesehatan/pengingat obat.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(90),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.medicalBlue.withAlpha(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18.0,
                          color: AppColors.medicalBlue,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Penyangkalan Medis',
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.medicalBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'JagaDosis adalah alat bantu pengingat dan pencatatan '
                      'obat. Aplikasi ini BUKAN pengganti nasihat, diagnosis, '
                      'atau perawatan dari dokter maupun tenaga kesehatan '
                      'profesional. Selalu konsultasikan keputusan medis Anda '
                      '(termasuk dosis dan jadwal obat) kepada tenaga '
                      'kesehatan. Dalam keadaan darurat, segera hubungi layanan '
                      'medis terdekat.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              _Section(
                title: '1. Penerimaan Ketentuan',
                body:
                    'Dengan mendaftar dan menggunakan JagaDosis, Anda setuju '
                    'untuk terikat oleh syarat dan ketentuan ini. Jika Anda '
                    'tidak menyetujuinya, mohon untuk tidak menggunakan '
                    'aplikasi.',
              ),
              _Section(
                title: '2. Penggunaan Aplikasi',
                body:
                    'Anda bertanggung jawab atas keakuratan data yang Anda '
                    'masukkan, termasuk nama obat, dosis, dan jadwal. Aplikasi '
                    'menampilkan dan mengingatkan berdasarkan data yang Anda '
                    'isi sendiri.',
              ),
              _Section(
                title: '3. Batasan Tanggung Jawab',
                body:
                    'Kami berupaya menjaga aplikasi berjalan andal, namun tidak '
                    'menjamin pengingat selalu terkirim tepat waktu (misalnya '
                    'karena perangkat mati, tanpa koneksi, atau pengaturan '
                    'sistem). Kami tidak bertanggung jawab atas kerugian akibat '
                    'kelalaian penggunaan atau ketergantungan penuh pada '
                    'aplikasi.',
              ),
              _Section(
                title: '4. Akun Anda',
                body:
                    'Anda bertanggung jawab menjaga kerahasiaan kredensial akun '
                    'Anda. Segala aktivitas yang terjadi melalui akun Anda '
                    'menjadi tanggung jawab Anda.',
              ),
              _Section(
                title: '5. Larangan',
                body:
                    'Anda dilarang menyalahgunakan aplikasi, mencoba mengakses '
                    'data pengguna lain, atau mengganggu keamanan dan '
                    'operasional layanan.',
              ),
              _Section(
                title: '6. Perubahan Ketentuan',
                body:
                    'Ketentuan ini dapat diperbarui dari waktu ke waktu. '
                    'Perubahan penting akan diberitahukan melalui aplikasi.',
              ),

              const SizedBox(height: 8.0),
              Text(
                'Dengan mendaftar, Anda menyatakan telah membaca dan menyetujui '
                'syarat & ketentuan ini.',
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
