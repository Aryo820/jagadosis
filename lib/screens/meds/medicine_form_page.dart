import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/services/notification_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified form page for both creating and editing a medicine.
///
/// Pass [medicine] to open in **edit** mode (fields are pre-filled and saving
/// updates the existing record). Leave it null to open in **add** mode.
class MedicineFormPage extends StatefulWidget {
  /// The medicine to edit. When null, the form operates in "add" mode.
  final MedicineModel? medicine;

  const MedicineFormPage({super.key, this.medicine});

  /// Whether the form is editing an existing medicine.
  bool get isEditing => medicine != null;

  @override
  State<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends State<MedicineFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageValueController = TextEditingController();

  final MedicineRepository _repository = MedicineRepository();
  final NotificationService _notificationService = NotificationService();

  // Selections
  String _selectedDosageUnit = 'Tablet';
  String _selectedFrequency = '1x Sehari';
  String _selectedFoodRelation = 'Sesudah Makan';
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

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
    'Sebelum Tidur',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _populateFromMedicine(widget.medicine!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageValueController.dispose();
    super.dispose();
  }

  /// Pre-fills the form fields from an existing medicine when editing.
  void _populateFromMedicine(MedicineModel med) {
    _nameController.text = med.medicineName;

    // Parse dose string. Supports two historical formats:
    //   Old: "500 mg • Tablet • Sesudah Makan • 1x Sehari" (4 parts)
    //   New: "500 Tablet • Sesudah Makan • 1x Sehari"      (3 parts)
    final parts = med.dose.split(' • ');
    if (parts.length >= 4) {
      _applyDoseParts(
        dosageAndUnit: parts[0].trim(),
        relation: parts[2].trim(),
        frequency: parts[3].trim(),
      );
    } else if (parts.length == 3) {
      _applyDoseParts(
        dosageAndUnit: parts[0].trim(),
        relation: parts[1].trim(),
        frequency: parts[2].trim(),
      );
    } else {
      // Unknown format: keep the raw value in the dosage field.
      _dosageValueController.text = med.dose;
    }

    // Parse scheduleTime: e.g. "08:00, 20:00"
    _selectedTimes = _parseScheduleTimes(med.scheduleTime);
  }

  /// Applies parsed dose components to the form state, registering any
  /// non-standard values so the dropdowns/chips can still display them.
  void _applyDoseParts({
    required String dosageAndUnit,
    required String relation,
    required String frequency,
  }) {
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
  }

  /// Parses a comma-separated "HH:mm" schedule string into TimeOfDay values.
  /// Falls back to a single 08:00 entry when nothing valid is found.
  List<TimeOfDay> _parseScheduleTimes(String scheduleTime) {
    final result = <TimeOfDay>[];
    for (final tStr in scheduleTime.split(',')) {
      final timeParts = tStr.trim().split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour != null && minute != null) {
          result.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
    }
    if (result.isEmpty) {
      result.add(const TimeOfDay(hour: 8, minute: 0));
    }
    return result;
  }

  /// Adjusts the number of time pickers to match the selected frequency.
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
        _selectedTimes.add(
          defaultTimes[_selectedTimes.length % defaultTimes.length],
        );
      }
    } else if (_selectedTimes.length > count) {
      _selectedTimes = _selectedTimes.sublist(0, count);
    }
  }

  /// Validates, persists (insert or update), and (re)schedules notifications.
  void _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    // Sort times chronologically.
    final sortedTimes = List<TimeOfDay>.from(_selectedTimes)
      ..sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });

    final String formattedTime = sortedTimes.map((t) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }).join(', ');

    // Combine dose, unit, relation and frequency for comprehensive UI display.
    final String doseDescription =
        '${_dosageValueController.text} $_selectedDosageUnit • $_selectedFoodRelation • $_selectedFrequency';

    final existing = widget.medicine;
    final medicine = MedicineModel(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: _nameController.text.trim(),
      dose: doseDescription,
      scheduleTime: formattedTime,
      status: existing?.status ?? 'pending',
      enableNotification: existing?.enableNotification ?? true,
    );

    if (widget.isEditing) {
      await _repository.updateMedicine(medicine);
      // Cancel old notifications and schedule new ones with updated times.
      await _notificationService.cancelForMedicine(medicine.id);
      await _notificationService.scheduleForMedicine(medicine);
    } else {
      await _repository.addMedicine(medicine);
      await _notificationService.scheduleForMedicine(medicine);
    }

    if (!mounted) return;
    _showSuccessSheet();
  }

  /// Shows the success bottom sheet, with copy adapted to add/edit mode.
  void _showSuccessSheet() {
    final String title =
        widget.isEditing ? 'Obat Berhasil Diperbarui' : 'Obat Berhasil Disimpan';
    final String message = widget.isEditing
        ? '${_nameController.text} (${_dosageValueController.text} $_selectedDosageUnit) telah diperbarui.'
        : '${_nameController.text} (${_dosageValueController.text} $_selectedDosageUnit) telah ditambahkan ke daftar obat Anda.';

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                message,
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
                    Navigator.pop(context, true); // Back to list with reload flag
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
          widget.isEditing ? 'Ubah Detail Obat' : 'Tambah Obat Baru',
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
                _buildCard(child: _buildBasicInfoSection()),
                const SizedBox(height: 24.0),

                // Section 2: Aturan Pakai & Waktu
                _buildSectionHeader('Aturan Pakai & Waktu'),
                const SizedBox(height: 12.0),
                _buildCard(child: _buildScheduleSection()),
                const SizedBox(height: 24.0),

                // Button Simpan
                _buildSaveButton(),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama Obat
        _buildLabel('Nama Obat'),
        TextFormField(
          controller: _nameController,
          style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14.0),
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
                  _buildDropdown(
                    value: _selectedDosageUnit,
                    items: _dosageUnits,
                    horizontalPadding: 12.0,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedDosageUnit = newValue);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frekuensi
        _buildLabel('Frekuensi'),
        _buildDropdown(
          value: _selectedFrequency,
          items: _frequencies,
          horizontalPadding: 16.0,
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFrequency = newValue;
                _updateTimePickersCount(newValue);
              });
            }
          },
        ),
        const SizedBox(height: 16.0),

        // Hubungan dengan Makanan
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
                  setState(() => _selectedFoodRelation = relation);
                }
              },
              selectedColor: _selectedColor.withAlpha(40),
              labelStyle: GoogleFonts.inter(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _selectedColor : AppColors.textGrey,
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
        _buildLabel(
          _selectedFrequency == 'Sesuai Kebutuhan'
              ? 'Waktu Konsumsi (Opsional)'
              : 'Waktu Konsumsi (Alarm)',
        ),
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
                  if (picked != null && picked != _selectedTimes[index]) {
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
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
              widget.isEditing ? 'Simpan Perubahan' : 'Simpan Obat',
              style: GoogleFonts.inter(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable helper widgets
  // ---------------------------------------------------------------------------

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

  /// Reusable styled dropdown used for both the unit and frequency selectors.
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double horizontalPadding,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGrey,
          ),
          style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14.0),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
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
