import 'dart:async';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/screens/dashboard_page.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Routes between the authenticated and unauthenticated parts of the app based
/// on Firebase Auth as the single source of truth.
///
/// Listening to [FirebaseAuth.authStateChanges] means a persisted session is
/// honoured on cold start and any sign-out (from anywhere) reactively falls
/// back to [LoginPage] — no more relying on a separately-tracked SharedPreferences
/// login flag that could drift out of sync with the actual Firebase session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still restoring the persisted session — show a brief loader.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoading();
        }

        final user = snapshot.data;
        if (user != null) {
          // Keep the local display cache (name/email) in sync so the greeting
          // and profile never render blank when a session is restored without a
          // fresh login (e.g. app relaunch). No-op once the cache is populated.
          _syncProfileCache(user);
          return const DashboardPage();
        }

        return const LoginPage();
      },
    );
  }

  /// Backfills the SharedPreferences display cache from the Firebase user when
  /// it hasn't been populated yet (login already saves it explicitly).
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
