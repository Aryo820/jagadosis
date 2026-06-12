import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMedicinePage extends StatefulWidget {
  final VoidCallback? onMedicineAdded;

  const AddMedicinePage({super.key, this.onMedicineAdded});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageValueController = TextEditingController();

  // Selections
  String _selectedDosageUnit = 'mg';
  String _selectedForm = 'Tablet';
  String _selectedFrequency = '1x Sehari';
  String _selectedFoodRelation = 'Sesudah Makan';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  final Color _selectedColor = AppColors.medicalBlue;

  final List<String> _dosageUnits = ['mg', 'mcg', 'ml', 'IU', 'gr', 'Pil', 'L'];
  final List<String> _forms = ['Tablet', 'Kapsul', 'Sirup', 'Injeksi', 'Tetes'];
  final List<String> _frequencies = [
    '1x Sehari',
    '2x Sehari',
    '3x Sehari',
    '4x Sehari',
    'Sesuai Kebutuhan',
  ];
  final List<String> _foodRelations = [
    'Sebelum Makan',
    'Sesudah Makan',
    'Bersama Makanan',
    'Sebelum Tidur',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageValueController.dispose();
    super.dispose();
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      final String formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Combine dose, unit, form, relation and frequency to display comprehensive info in UI
      final String doseDescription =
          '${_dosageValueController.text} $_selectedDosageUnit • $_selectedForm • $_selectedFoodRelation • $_selectedFrequency';

      final medicine = MedicineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineName: _nameController.text.trim(),
        dose: doseDescription,
        scheduleTime: formattedTime,
        status: 'pending',
      );

      final repository = MedicineRepository();
      await repository.addMedicine(medicine);

      if (!mounted) return;

      // Show dynamic beautiful success modal sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    color: _selectedColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: _selectedColor,
                      size: 40.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Obat Berhasil Disimpan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${_nameController.text} (${_dosageValueController.text} $_selectedDosageUnit) telah ditambahkan ke daftar obat Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.0,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  height: 52.0,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pop(
                        context,
                        true,
                      ); // Go back to meds list with reload flag = true
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Kembali ke Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Obat Baru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Informasi Dasar
                _buildSectionHeader('Informasi Dasar'),
                const SizedBox(height: 12.0),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Obat
                      _buildLabel('Nama Obat'),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.inter(
                          color: AppColors.textDark,
                          fontSize: 14.0,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Paracetamol, Amoxicillin',
                          icon: Icons.edit_note_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama obat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Dosis & Satuan
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Dosis'),
                                TextFormField(
                                  controller: _dosageValueController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textDark,
                                    fontSize: 14.0,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: 'Contoh: 500',
                                    icon: Icons.scale_rounded,
                                  ),
                                  // validator: (value) {
                                  //   if (value == null || value.trim().isEmpty) {
                                  //     return 'Dosis kosong';
                                  //   }
                                  //   return null;
                                  // },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Satuan'),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDosageUnit,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.textGrey,
                                      ),
                                      style: GoogleFonts.inter(
                                        color: AppColors.textDark,
                                        fontSize: 14.0,
                                      ),
                                      items: _dosageUnits.map((String unit) {
                                        return DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(
                                            () =>
                                                _selectedDosageUnit = newValue,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Bentuk Sediaan
                      _buildLabel('Bentuk Sediaan'),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _forms.map((form) {
                          final isSelected = _selectedForm == form;
                          return ChoiceChip(
                            label: Text(form),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedForm = form);
                              }
                            },
                            selectedColor: _selectedColor.withAlpha(40),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 13.0,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? _selectedColor
                                  : AppColors.textGrey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(
                                color: isSelected
                                    ? _selectedColor
                                    : AppColors.outlineVariant.withAlpha(150),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            showCheckmark: false,
                            backgroundColor: Colors.transparent,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                // Section 2: Aturan Pakai
                _buildSectionHeader('Aturan Pakai & Waktu'),
                const SizedBox(height: 12.0),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Frekuensi Konsumsi
                      _buildLabel('Frekuensi'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineVariant),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFrequency,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textGrey,
                            ),
                            style: GoogleFonts.inter(
                              color: AppColors.textDark,
                              fontSize: 14.0,
                            ),
                            items: _frequencies.map((String freq) {
                              return DropdownMenuItem<String>(
                                value: freq,
                                child: Text(freq),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() => _selectedFrequency = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Waktu Konsumsi
                      _buildLabel('Hubungan dengan Makanan'),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _foodRelations.map((relation) {
                          final isSelected = _selectedFoodRelation == relation;
                          return ChoiceChip(
                            label: Text(relation),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(
                                  () => _selectedFoodRelation = relation,
                                );
                              }
                            },
                            selectedColor: _selectedColor.withAlpha(40),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 13.0,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? _selectedColor
                                  : AppColors.textGrey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: BorderSide(
                                color: isSelected
                                    ? _selectedColor
                                    : AppColors.outlineVariant.withAlpha(150),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            showCheckmark: false,
                            backgroundColor: Colors.transparent,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16.0),

                      // Waktu Konsumsi
                      _buildLabel('Waktu Konsumsi'),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null && picked != _selectedTime) {
                            setState(() {
                              _selectedTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: AppColors.textGrey,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Text(
                                    _selectedTime.format(context),
                                    style: GoogleFonts.inter(
                                      color: AppColors.textDark,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Ubah Waktu',
                                style: GoogleFonts.inter(
                                  color: AppColors.medicalBlue,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                // Button Simpan
                SizedBox(
                  width: double.infinity,
                  height: 54.0,
                  child: ElevatedButton(
                    onPressed: _saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      elevation: 4.0,
                      shadowColor: _selectedColor.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'Simpan Obat',
                          style: GoogleFonts.inter(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
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
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark.withAlpha(200),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14.0,
        color: AppColors.textGrey.withAlpha(160),
      ),
      prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20.0),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _selectedColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 12.0, color: Colors.redAccent),
    );
  }
}
