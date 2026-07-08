import 'package:aplikasi/services/auth_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gates write actions (creating/editing data tied to the account) behind email
/// verification. Reading stays open — only actions that persist identity data
/// are guarded — so an unverified user can explore the app but can't populate
/// it, and thus a throwaway/misspelled email never seeds real records.
///
/// Verification is Firebase's only proof that the address genuinely belongs to
/// the user: sign-up succeeds for any well-formed email, so [emailVerified] is
/// what we check, not mere account existence.
class EmailVerificationGuard {
  EmailVerificationGuard._();

  static final AuthService _authService = AuthService();

  /// Call at the start of a guarded action:
  ///
  /// ```dart
  /// if (!await EmailVerificationGuard.ensureVerified(context)) return;
  /// ```
  ///
  /// Refreshes the user from the server first so a verification the user just
  /// completed in their browser is picked up without needing to re-login.
  /// Returns true when the action may proceed; false after showing the prompt.
  static Future<bool> ensureVerified(BuildContext context) async {
    // Best-effort refresh: a network hiccup shouldn't crash the action, it just
    // means we fall back to the last-known (unverified) status and prompt.
    try {
      await _authService.reloadCurrentUser();
    } catch (_) {}

    if (_authService.isEmailVerified) return true;

    if (!context.mounted) return false;
    await _showPrompt(context);
    return false;
  }

  /// Resends the verification email and reports the outcome via a SnackBar.
  /// Shared by the guard dialog and the home-screen banner.
  static Future<void> resendVerificationEmail(BuildContext context) async {
    try {
      await _authService.sendEmailVerification();
      if (!context.mounted) return;
      _snack(
        context,
        'Link verifikasi telah dikirim ulang. Cek kotak masuk & folder spam.',
        AppColors.wellnessGreen,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      _snack(
        context,
        AuthService.messageFromException(e),
        Colors.redAccent,
      );
    }
  }

  static void _snack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static Future<void> _showPrompt(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        bool sending = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlue.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppColors.medicalBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verifikasi Email Dulu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Fitur ini memerlukan email yang sudah terverifikasi. Silakan '
                'buka link verifikasi yang kami kirim ke email Anda, lalu coba '
                'lagi. Belum menerima emailnya? Kirim ulang di bawah.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.inter(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setState(() => sending = true);
                          await resendVerificationEmail(dialogContext);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medicalBlue,
                    foregroundColor: AppColors.surfaceWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surfaceWhite,
                            ),
                          ),
                        )
                      : Text(
                          'Kirim Ulang Link',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
