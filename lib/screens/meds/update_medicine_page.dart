import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateMedicinePage extends StatefulWidget {
  final MedicineModel medicine;

  const UpdateMedicinePage({super.key, required this.medicine});

  @override
  State<UpdateMedicinePage> createState() => _UpdateMedicinePageState();
}

class _UpdateMedicinePageState extends State<UpdateMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageValueController = TextEditingController();

  // Selections
  String _selectedDosageUnit = 'Tablet';
  String _selectedFrequency = '1x Sehari';
  String _selectedFoodRelation = 'Sesudah Makan';
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  void _updateTimePickersCount(String frequency) {
    int count = 1;
    if (frequency == '2x Sehari') {
      count = 2;
    } else if (frequency == '3x Sehari') {
      count = 3;
    } else if (frequency == '4x Sehari') {
      count = 4;
    }

    if (_selectedTimes.length < count) {
      final List<TimeOfDay> defaultTimes = [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 6, minute: 0),
      ];
      while (_selectedTimes.length < count) {
        _selectedTimes.add(defaultTimes[_selectedTimes.length % defaultTimes.length]);
      }
    } else if (_selectedTimes.length > count) {
      _selectedTimes = _selectedTimes.sublist(0, count);
    }
  }

  final Color _selectedColor = AppColors.medicalBlue;

  final List<String> _dosageUnits = [
    'Tablet',
    'Kapsul',
    'Sendok Makan (sdm)',
    'Sendok Teh (sdt)',
    'Tetes',
    'Semprot',
    'Sachet / Bungkus',
  ];
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
    'Waktu Tidur',
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.medicine;
    _nameController.text = med.medicineName;

    // Parse dose string: can be "500 mg • Tablet • Sesudah Makan • 1x Sehari" or "1 Tablet • Sesudah Makan • 1x Sehari"
    final parts = med.dose.split(' • ');
    if (parts.length >= 4) {
      // Old format
      final dosageAndUnit = parts[0].trim();
      final relation = parts[2].trim();
      final frequency = parts[3].trim();

      // Parse dosage and unit
      final dosageParts = dosageAndUnit.split(' ');
      if (dosageParts.isNotEmpty) {
        _dosageValueController.text = dosageParts[0];
        if (dosageParts.length > 1) {
          final unit = dosageParts.sublist(1).join(' ');
          if (!_dosageUnits.contains(unit)) {
            _dosageUnits.add(unit);
          }
          _selectedDosageUnit = unit;
        }
      }

      if (!_foodRelations.contains(relation)) {
        _foodRelations.add(relation);
      }
      _selectedFoodRelation = relation;

      if (!_frequencies.contains(frequency)) {
        _frequencies.add(frequency);
      }
      _selectedFrequency = frequency;
    } else if (parts.length == 3) {
      // New format
      final dosageAndUnit = parts[0].trim();
      final relation = parts[1].trim();
      final frequency = parts[2].trim();

      // Parse dosage and unit
      final dosageParts = dosageAndUnit.split(' ');
      if (dosageParts.isNotEmpty) {
        _dosageValueController.text = dosageParts[0];
        if (dosageParts.length > 1) {
          final unit = dosageParts.sublist(1).join(' ');
          if (!_dosageUnits.contains(unit)) {
            _dosageUnits.add(unit);
          }
          _selectedDosageUnit = unit;
        }
      }

      if (!_foodRelations.contains(relation)) {
        _foodRelations.add(relation);
      }
      _selectedFoodRelation = relation;

      if (!_frequencies.contains(frequency)) {
        _frequencies.add(frequency);
      }
      _selectedFrequency = frequency;
    } else {
      // Fallback
      _dosageValueController.text = med.dose;
    }

    // Parse scheduleTime: e.g. "08:00, 20:00"
    final timesList = med.scheduleTime.split(', ');
    _selectedTimes = [];
    for (final tStr in timesList) {
      final timeParts = tStr.trim().split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour != null && minute != null) {
          _selectedTimes.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
    }
    if (_selectedTimes.isEmpty) {
      _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageValueController.dispose();
    super.dispose();
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      // Sort times chronologically
      final sortedTimes = List<TimeOfDay>.from(_selectedTimes)
        ..sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });

      final String formattedTime = sortedTimes.map((t) {
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }).join(', ');

      // Combine dose, unit, relation and frequency to display comprehensive info in UI
      final String doseDescription =
          '${_dosageValueController.text} $_selectedDosageUnit • $_selectedFoodRelation • $_selectedFrequency';

      final updatedMedicine = MedicineModel(
        id: widget.medicine.id,
        medicineName: _nameController.text.trim(),
        dose: doseDescription,
        scheduleTime: formattedTime,
        status: widget.medicine.status,
      );

      final repository = MedicineRepository();
      await repository.updateMedicine(updatedMedicine);

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
                  'Obat Berhasil Diperbarui',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${_nameController.text} (${_dosageValueController.text} $_selectedDosageUnit) telah diperbarui.',
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
          'Ubah Detail Obat',
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
                                setState(() {
                                  _selectedFrequency = newValue;
                                  _updateTimePickersCount(newValue);
                                });
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

                      // Waktu Konsumsi (Alarm)
                      _buildLabel(_selectedFrequency == 'Sesuai Kebutuhan'
                          ? 'Waktu Konsumsi (Opsional)'
                          : 'Waktu Konsumsi (Alarm)'),
                      Column(
                        children: List.generate(_selectedTimes.length, (index) {
                          final timeStr = _selectedTimes[index].format(context);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTimes[index],
                                );
                                if (picked != null &&
                                    picked != _selectedTimes[index]) {
                                  setState(() {
                                    _selectedTimes[index] = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: AppColors.textGrey,
                                        ),
                                        const SizedBox(width: 12.0),
                                        Text(
                                          _selectedFrequency == 'Sesuai Kebutuhan'
                                              ? 'Waktu: $timeStr'
                                              : 'Alarm ke-${index + 1}: $timeStr',
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
                          );
                        }),
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
                          'Simpan Perubahan',
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
