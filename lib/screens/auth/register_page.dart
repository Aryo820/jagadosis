import 'package:aplikasi/extensions/navigator.dart';
import 'package:aplikasi/screens/legal/privacy_policy_page.dart';
import 'package:aplikasi/screens/legal/terms_and_conditions_page.dart';
import 'package:aplikasi/services/auth_service.dart';
import 'package:aplikasi/services/profile_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToPolicy = false;

  // Held as fields (not created inline in build) so they can be disposed and
  // aren't rebuilt on every setState.
  late final TapGestureRecognizer _policyTapRecognizer =
      TapGestureRecognizer()
        ..onTap = () => context.push(const PrivacyPolicyPage());
  late final TapGestureRecognizer _termsTapRecognizer =
      TapGestureRecognizer()
        ..onTap = () => context.push(const TermsAndConditionsPage());

  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      await _authService.register(
        name: name,
        email: email,
        password: _passwordController.text,
      );

      // Seed the Firestore profile document while still authenticated (the
      // security rules require the write to come from the account itself).
      // The register button is gated on _agreedToPolicy, so recording the
      // accepted policy version here captures a truthful consent trail.
      await _profileService.createInitial(
        name: name,
        email: email,
        consentVersion: privacyPolicyVersion,
        termsVersion: termsVersion,
      );

      // Firebase signs the new account in automatically. Sign back out so the
      // app state stays consistent with the "please log in" UX below (and so
      // AuthGate doesn't jump straight to the dashboard on the next launch).
      await _authService.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pendaftaran berhasil! Kami telah mengirim link verifikasi ke '
            'email Anda. Silakan cek kotak masuk (dan folder spam), lalu masuk.',
          ),
          backgroundColor: AppColors.wellnessGreen,
          duration: Duration(seconds: 6),
        ),
      );
      Navigator.pop(context); // Go back to login page
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.messageFromException(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _policyTapRecognizer.dispose();
    _termsTapRecognizer.dispose();
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
                    // Brand / Logo Area
                    const SizedBox(height: 12.0),
                    Text(
                      'JagaDosis',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.medicalBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Mulai langkah sehat Anda hari ini bersama keluarga tercinta.',
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),

                    // Registration Card
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
                            Center(
                              child: Text(
                                'Registrasi Akun Baru',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            // Full Name Field
                            Text(
                              'Nama Lengkap',
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama lengkap',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14.0,
                                  color: AppColors.textGrey.withAlpha(178),
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
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
                                  return 'Nama lengkap tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Email Field
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
                                hintText: 'contoh@email.com',
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
                            const SizedBox(height: 16.0),

                            // Password Field
                            Text(
                              'Kata Sandi',
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(
                                fontSize: 14.0,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Minimal 8 karakter',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14.0,
                                  color: AppColors.textGrey.withAlpha(178),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textGrey,
                                  size: 20.0,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textGrey,
                                    size: 20.0,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
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
                                  return 'Kata sandi tidak boleh kosong';
                                }
                                if (value.length < 8) {
                                  return 'Kata sandi minimal 8 karakter';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16.0),

                            // Privacy policy consent
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: Checkbox(
                                    value: _agreedToPolicy,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreedToPolicy = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.medicalBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Saya menyetujui ',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.0,
                                        color: AppColors.textGrey,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Syarat & Ketentuan',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.medicalBlue,
                                            height: 1.4,
                                          ),
                                          recognizer: _termsTapRecognizer,
                                        ),
                                        const TextSpan(text: ' dan '),
                                        TextSpan(
                                          text: 'Kebijakan Privasi',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.medicalBlue,
                                            height: 1.4,
                                          ),
                                          recognizer: _policyTapRecognizer,
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24.0),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 52.0,
                              child: ElevatedButton(
                                onPressed: (_isLoading || !_agreedToPolicy)
                                    ? null
                                    : register,
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
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22.0,
                                        height: 22.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.surfaceWhite,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Daftar',
                                            style: GoogleFonts.inter(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 18.0,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16.0),

                            // Switch to Login Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sudah punya akun? ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.0,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Masuk',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.medicalBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
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
