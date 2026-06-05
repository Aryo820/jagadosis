import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: Stack(
        children: [
          // Subtle top gradient background decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE6EEFF), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main Content Area
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Illustration Area
                    const SizedBox(height: 40.0),
                    Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6EEFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.medicalBlue.withAlpha(40),
                          width: 2.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 40.0,
                          color: AppColors.medicalBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Lupa Kata Sandi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Masukkan email Anda untuk menerima instruksi reset kata sandi',
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32.0),

                    // Forgot Password Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: AppColors.outlineVariant.withAlpha(128),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 24.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'nama@email.com',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14.0,
                                  color: AppColors.textGrey.withAlpha(178),
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.textGrey,
                                  size: 20.0,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 16.0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: AppColors.medicalBlue,
                                    width: 1.5,
                                  ),
                                ),
                                errorStyle: GoogleFonts.inter(fontSize: 12.0),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24.0),

                            // Send Instructions Button
                            SizedBox(
                              width: double.infinity,
                              height: 52.0,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // Action to send email
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.textDark,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16.0,
                                          ),
                                        ),
                                        content: Row(
                                          children: [
                                            Container(
                                              width: 32.0,
                                              height: 32.0,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 18.0,
                                              ),
                                            ),
                                            const SizedBox(width: 12.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Email Terkirim!',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Cek kotak masuk email Anda sekarang.',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.0,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.medicalBlue,
                                  foregroundColor: AppColors.surfaceWhite,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Kirim',
                                      style: GoogleFonts.inter(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    const Icon(Icons.send_rounded, size: 16.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Back to Login Link
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                      child: Text(
                        'Kembali ke Masuk',
                        style: GoogleFonts.inter(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.medicalBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
