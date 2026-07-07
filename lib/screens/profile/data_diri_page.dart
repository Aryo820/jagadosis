import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/models/user_profile_model.dart';
import 'package:aplikasi/services/profile_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataDiriPage extends StatefulWidget {
  const DataDiriPage({super.key});

  @override
  State<DataDiriPage> createState() => _DataDiriPageState();
}

class _DataDiriPageState extends State<DataDiriPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _birthDateController;
  late TextEditingController _allergiesController;
  
  final ProfileService _profileService = ProfileService();
  bool _isSaving = false;

  String _selectedGender = '';
  String _selectedBloodType = '';

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O', '-'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: PreferenceHandler.userName);
    _birthDateController = TextEditingController(text: PreferenceHandler.userBirthDate);
    _allergiesController = TextEditingController(text: PreferenceHandler.userAllergies);
    
    final savedGender = PreferenceHandler.userGender;
    if (_genders.contains(savedGender)) {
      _selectedGender = savedGender;
    }
    
    final savedBlood = PreferenceHandler.userBloodType;
    if (_bloodTypes.contains(savedBlood)) {
      _selectedBloodType = savedBlood;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.medicalBlue,
              onPrimary: AppColors.surfaceWhite,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Persist to Firestore (durable, cross-device) and the local cache in one
    // call. Email stays read-only, so it's carried over unchanged.
    final profile = UserProfile(
      name: _nameController.text.trim(),
      email: PreferenceHandler.userEmail,
      birthDate: _birthDateController.text,
      gender: _selectedGender,
      bloodType: _selectedBloodType,
      allergies: _allergiesController.text,
    );

    try {
      await _profileService.saveProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data diri berhasil diperbarui',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.wellnessGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context, true); // Return true so profile page rebuilds name
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan. Periksa koneksi dan coba lagi.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Data Diri',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Pribadi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12.0),
              Container(
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Nama Lengkap
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(color: AppColors.textDark),
                      decoration: _buildInputDecoration(
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // Email (Read Only)
                    TextFormField(
                      initialValue: PreferenceHandler.userEmail,
                      enabled: false,
                      style: GoogleFonts.inter(color: AppColors.textGrey.withAlpha(150)),
                      decoration: _buildInputDecoration(
                        label: 'Alamat Email',
                        icon: Icons.email_outlined,
                        helperText: 'Email tidak dapat diubah',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Tanggal Lahir
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: () => _selectBirthDate(context),
                      style: GoogleFonts.inter(color: AppColors.textDark),
                      decoration: _buildInputDecoration(
                        label: 'Tanggal Lahir',
                        icon: Icons.calendar_month_outlined,
                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Jenis Kelamin
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender.isEmpty ? null : _selectedGender,
                      dropdownColor: AppColors.surfaceWhite,
                      style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14),
                      decoration: _buildInputDecoration(
                        label: 'Jenis Kelamin',
                        icon: Icons.wc_rounded,
                      ),
                      items: _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Informasi Medis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12.0),
              Container(
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Golongan Darah
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBloodType.isEmpty ? null : _selectedBloodType,
                      dropdownColor: AppColors.surfaceWhite,
                      style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14),
                      decoration: _buildInputDecoration(
                        label: 'Golongan Darah',
                        icon: Icons.bloodtype_outlined,
                      ),
                      items: _bloodTypes.map((blood) {
                        return DropdownMenuItem(
                          value: blood,
                          child: Text(blood),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // Alergi Obat
                    TextFormField(
                      controller: _allergiesController,
                      maxLines: 3,
                      style: GoogleFonts.inter(color: AppColors.textDark),
                      decoration: _buildInputDecoration(
                        label: 'Riwayat Alergi / Kondisi Medis',
                        icon: Icons.warning_amber_rounded,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              // Simpan Button
              SizedBox(
                width: double.infinity,
                height: 52.0,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medicalBlue,
                    foregroundColor: AppColors.surfaceWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22.0,
                          height: 22.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surfaceWhite,
                            ),
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
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
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperStyle: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 11),
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.medicalBlue, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.backgroundBlue.withAlpha(100),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withAlpha(100)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withAlpha(100)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.medicalBlue, width: 1.5),
      ),
    );
  }
}
