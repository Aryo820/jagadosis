import 'dart:async';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/screens/dashboard_page.dart';
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
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo scale: 0.0 -> 1.0 (with elastic out effect for premium feel)
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Logo fade: 0.0 -> 1.0
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // App title text fade
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // App title slide up slightly
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
          ),
        );

    // Tagline fade
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animation
    _controller.forward();

    // Navigate to Login Screen after 3 seconds
    _timer = Timer(const Duration(seconds: 15), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    final Widget destination = PreferenceHandler.isLogin
        ? const DashboardPage()
        : const LoginPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
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
              Color(0xFF0F6BD7), // Lighter medical blue gradient top
              Color(0xFF003D7C), // Darker deep medical blue bottom
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background patterns/glows
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
            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Container
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

                  // Animated Text (Title + Tagline)
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

                  // Animated Tagline
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

            // Bottom loading/branding indicator
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
