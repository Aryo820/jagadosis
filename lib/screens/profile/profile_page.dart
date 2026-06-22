import 'dart:io';

import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/screens/profile/data_diri_page.dart';
import 'package:aplikasi/screens/profile/emergency_contacts_page.dart';
import 'package:aplikasi/screens/profile/help_center_page.dart';
import 'package:aplikasi/screens/profile/notification_settings_page.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  /// Loads the saved profile photo path from SharedPreferences.
  void _loadProfilePhoto() {
    final path = PreferenceHandler.profilePhoto;
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  /// Copies the picked image to the app's permanent documents directory
  /// so it survives gallery deletions or cache clears.
  Future<File> _saveImagePermanently(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final savedImage = await image.copy('${directory.path}/$fileName');
    return savedImage;
  }

  /// Picks an image from the specified [source] (gallery or camera),
  /// saves it to app storage, and updates the preference.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Delete old photo file if it exists
      await _deleteOldPhotoFile();

      // Save to permanent storage
      final savedImage = await _saveImagePermanently(File(pickedFile.path));

      // Persist path
      await PreferenceHandler.saveProfilePhoto(savedImage.path);

      setState(() {
        _profileImage = savedImage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto profil berhasil diperbarui',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.wellnessGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEB5757),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Deletes the previous profile photo file from disk if it exists.
  Future<void> _deleteOldPhotoFile() async {
    final oldPath = PreferenceHandler.profilePhoto;
    if (oldPath != null) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
  }

  /// Deletes the profile photo entirely (file + preference).
  Future<void> _deleteProfilePhoto() async {
    await _deleteOldPhotoFile();
    await PreferenceHandler.removeProfilePhoto();

    setState(() {
      _profileImage = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto profil berhasil dihapus',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.medicalBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Shows a bottom sheet with options: gallery, camera, and delete.
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ubah Foto Profil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              // Gallery option
              _buildOptionTile(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri',
                subtitle: 'Ambil foto dari album galeri',
                color: AppColors.medicalBlue,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              // Camera option
              _buildOptionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Foto',
                subtitle: 'Buka kamera untuk foto baru',
                color: AppColors.wellnessGreen,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              // Delete option (only shown if a photo exists)
              if (_profileImage != null) ...[
                const SizedBox(height: 8),
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Hapus Foto',
                  subtitle: 'Kembali ke ikon default',
                  color: const Color(0xFFEB5757),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting the photo.
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Hapus Foto Profil?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Foto profil kamu akan dihapus dan kembali ke ikon default.',
            style: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteProfilePhoto();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB5757),
                foregroundColor: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds a single option tile for the bottom sheet.
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withAlpha(120),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Profile Header Section
            const SizedBox(height: 16.0),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        Container(
                          width: 110.0,
                          height: 110.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.outlineVariant.withAlpha(80),
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10.0,
                              ),
                            ],
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 64.0,
                                    color: AppColors.medicalBlue,
                                  ),
                                )
                              : null,
                        ),
                        // Edit Avatar FAB
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: AppColors.medicalBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surfaceWhite,
                                width: 2.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.surfaceWhite,
                              size: 16.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    PreferenceHandler.userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    PreferenceHandler.userEmail,
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: AppColors.textGrey,
                    ),
                  ),
                  if (PreferenceHandler.userGender.isNotEmpty ||
                      PreferenceHandler.userBloodType.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (PreferenceHandler.userGender.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.medicalBlue.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.wc_rounded,
                                  size: 14,
                                  color: AppColors.medicalBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  PreferenceHandler.userGender,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.medicalBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (PreferenceHandler.userGender.isNotEmpty &&
                            PreferenceHandler.userBloodType.isNotEmpty)
                          const SizedBox(width: 8),
                        if (PreferenceHandler.userBloodType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEB5757).withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bloodtype_outlined,
                                  size: 14,
                                  color: Color(0xFFEB5757),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gol. Darah: ${PreferenceHandler.userBloodType}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEB5757),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Medical Info Card
            if (PreferenceHandler.userBloodType.isNotEmpty ||
                PreferenceHandler.userBirthDate.isNotEmpty ||
                PreferenceHandler.userAllergies.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: AppColors.outlineVariant.withAlpha(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Medis',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMedicalDetailItem(
                            'Golongan Darah',
                            PreferenceHandler.userBloodType.isNotEmpty
                                ? PreferenceHandler.userBloodType
                                : '-',
                            Icons.bloodtype_outlined,
                            const Color(0xFFEB5757),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.outlineVariant.withAlpha(80),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMedicalDetailItem(
                            'Tanggal Lahir',
                            PreferenceHandler.userBirthDate.isNotEmpty
                                ? PreferenceHandler.userBirthDate
                                : '-',
                            Icons.calendar_month_outlined,
                            AppColors.medicalBlue,
                          ),
                        ),
                      ],
                    ),
                    if (PreferenceHandler.userAllergies.isNotEmpty) ...[
                      const SizedBox(height: 12.0),
                      const Divider(height: 1, color: Color(0xFFF1F3F9)),
                      const SizedBox(height: 12.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alergi / Kondisi Medis',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.0,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  PreferenceHandler.userAllergies,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16.0),

            // Settings Options List
            _buildSettingCard(
              'Data Diri',
              'Informasi pribadi dan rekam medis',
              Icons.person_outline_rounded,
              AppColors.medicalBlue,
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DataDiriPage()),
                );
                if (updated == true && mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Pengaturan Notifikasi',
              'Atur pengingat obat dan alarm',
              Icons.notifications_active_outlined,
              AppColors.wellnessGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Kontak Darurat',
              'Nomor penting dan dokter keluarga',
              Icons.emergency_outlined,
              const Color(0xFFEB5757),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyContactsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12.0),
            _buildSettingCard(
              'Pusat Bantuan',
              'FAQ dan panduan penggunaan aplikasi',
              Icons.help_center_outlined,
              AppColors.textGrey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 28.0),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52.0,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await PreferenceHandler.logOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB5757),
                  foregroundColor: AppColors.surfaceWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20.0),
                label: Text(
                  'Keluar',
                  style: GoogleFonts.inter(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    Color accentColor, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 24.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGrey,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.0,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
