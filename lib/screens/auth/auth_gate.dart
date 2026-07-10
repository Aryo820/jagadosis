import 'dart:async';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/screens/dashboard_page.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Mengarahkan pengguna antara bagian aplikasi yang sudah login dan yang belum,
/// dengan Firebase Auth sebagai satu-satunya sumber kebenaran status login.
///
/// Dengan mendengarkan [FirebaseAuth.authStateChanges], sesi yang tersimpan akan
/// dihormati saat aplikasi dibuka dari kondisi mati, dan setiap logout (dari mana
/// pun) secara reaktif mengembalikan pengguna ke [LoginPage] — tanpa perlu lagi
/// bergantung pada penanda login terpisah di SharedPreferences yang bisa tidak
/// sinkron dengan sesi Firebase yang sebenarnya.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Masih memulihkan sesi yang tersimpan — tampilkan loader sebentar.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoading();
        }

        final user = snapshot.data;
        if (user != null) {
          // Jaga agar cache tampilan lokal (nama/email) tetap sinkron, sehingga
          // sapaan dan profil tidak pernah tampil kosong ketika sesi dipulihkan
          // tanpa login ulang (misalnya saat aplikasi dibuka kembali). Tidak
          // melakukan apa-apa jika cache sudah terisi.
          _syncProfileCache(user);
          return const DashboardPage();
        }

        return const LoginPage();
      },
    );
  }

  /// Mengisi cache tampilan di SharedPreferences dari data pengguna Firebase
  /// jika cache tersebut belum terisi (saat login, data ini sudah disimpan
  /// secara eksplisit).
  void _syncProfileCache(User user) {
    if (PreferenceHandler.userName.isNotEmpty) return;

    final displayName = user.displayName?.trim();
    final email = user.email ?? '';
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'Pengguna');
    unawaited(PreferenceHandler.saveUser(name, email));
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.medicalBlue),
        ),
      ),
    );
  }
}
