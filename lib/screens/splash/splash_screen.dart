import 'dart:async';

import 'package:aplikasi/screens/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _taglineFadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Skala logo: 0.0 -> 1.0 (dengan efek elastic out agar terasa lebih menarik)
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Efek muncul (fade) logo: 0.0 -> 1.0
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Efek muncul (fade) untuk tagline
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Mulai animasi
    _controller.forward();

    // Pindah ke layar berikutnya setelah beberapa detik
    _timer = Timer(const Duration(seconds: 4), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    // Serahkan pengaturan rute ke AuthGate, yang menentukan antara Dashboard
    // atau Login berdasarkan sesi Firebase Auth yang aktif, bukan dari penanda
    // login lokal.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F6BD7), // Biru medis lebih terang di bagian atas gradien
              Color(0xFF003D7C), // Biru medis lebih gelap di bagian bawah gradien
            ],
          ),
        ),
        child: Stack(
          children: [
            // Pola/cahaya dekoratif pada latar belakang
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ),
            // Konten di tengah
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kontainer logo dengan animasi
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 196,
                      height: 196,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 16.0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Teks beranimasi (Judul + Tagline) — dinonaktifkan
                  // AnimatedBuilder(
                  //   animation: _controller,
                  //   builder: (context, child) {
                  //     return Opacity(
                  //       opacity: _textFadeAnimation.value,
                  //       child: FractionalTranslation(
                  //         translation: _textSlideAnimation.value,
                  //         child: child,
                  //       ),
                  //     );
                  //   },
                  //   child: Column(
                  //     children: [
                  //       Text(
                  //         'JagaDosis',
                  //         style: GoogleFonts.plusJakartaSans(
                  //           fontSize: 32.0,
                  //           fontWeight: FontWeight.bold,
                  //           color: Colors.white,
                  //           letterSpacing: -0.5,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8.0),
                  //     ],
                  //   ),
                  // ),

                  // Tagline beranimasi
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _taglineFadeAnimation.value,
                        child: child,
                      );
                    },
                    child: Text(
                      'Pendamping Pintar Jadwal Obat Anda',
                      style: GoogleFonts.inter(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withAlpha(200),
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Indikator loading/branding di bagian bawah
            Positioned(
              bottom: 48.0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _taglineFadeAnimation.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    SizedBox(
                      width: 40.0,
                      height: 2.0,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withAlpha(50),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      'v1.0.0',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
