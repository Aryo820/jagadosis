import 'package:aplikasi/models/medicine_model.dart';
import 'package:aplikasi/repositories/medicine_repository.dart';
import 'package:aplikasi/screens/meds/add_medicine_page.dart';
import 'package:aplikasi/screens/meds/update_medicine_page.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  final MedicineRepository _medicineRepo = MedicineRepository();
  List<MedicineModel> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  /// Fetches all active medicines from the database.
  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _medicineRepo.getAllMedicines();
      setState(() {
        _medicines = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Deletes a medicine by ID and reloads the list.
  Future<void> _deleteMedicine(String id) async {
    await _medicineRepo.deleteMedicine(id);
    _loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Obat Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${_medicines.length} OBAT',
                    style: GoogleFonts.inter(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.medicalBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(
                    color: AppColors.medicalBlue,
                  ),
                ),
              )
            else if (_medicines.isEmpty)
              _buildEmptyState()
            else
              ..._medicines.map((medicine) {
                // Parse dose components: "value unit • form • relation • frequency"
                final parts = medicine.dose.split(' • ');
                final dosage = parts.isNotEmpty ? parts[0] : medicine.dose;
                final form = parts.length > 1 ? parts[1] : '';
                final relation = parts.length > 2 ? parts[2] : '';
                final frequency = parts.length > 3 ? parts[3] : '';

                // Map form to appropriate icon and color
                IconData icon = Icons.medication_rounded;
                Color color = AppColors.medicalBlue;
                if (form.toLowerCase().contains('kapsul')) {
                  icon = Icons.healing_rounded;
                  color = AppColors.wellnessGreen;
                } else if (form.toLowerCase().contains('sirup')) {
                  icon = Icons.vaccines_rounded;
                  color = const Color(0xFF934700);
                } else if (form.toLowerCase().contains('tetes')) {
                  icon = Icons.opacity_rounded;
                  color = Colors.teal;
                }

                final doseText =
                    '$dosage${form.isNotEmpty ? ' • 1 $form' : ''}';
                final instructionText =
                    '${frequency.isNotEmpty ? frequency : '1x Sehari'}${relation.isNotEmpty ? ' • $relation' : ''}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildMedCard(
                    context,
                    medicine.medicineName,
                    doseText,
                    instructionText,
                    'Jadwal minum: Pukul ${medicine.scheduleTime}',
                    icon,
                    color,
                    medicineId: medicine.id,
                    medicine: medicine,
                  ),
                );
              }),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicinePage()),
          );
          if (result == true) {
            _loadMedicines();
          }
        },
        backgroundColor: AppColors.medicalBlue,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Tambah Obat',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Premium empty state when there are no medicines registered.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.medicalBlue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 64.0,
                color: AppColors.medicalBlue,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Belum Ada Obat Terdaftar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Tambahkan obat baru untuk mulai memantau dosis dan jadwal minum obat Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a dynamic medication card with a context-based delete menu.
  Widget _buildMedCard(
    BuildContext context,
    String name,
    String dosage,
    String instructions,
    String timeInfo,
    IconData icon,
    Color color, {
    required String medicineId,
    required MedicineModel medicine,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.outlineVariant.withAlpha(50),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.0),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    dosage,
                    style: GoogleFonts.inter(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    instructions,
                    style: GoogleFonts.inter(
                      fontSize: 12.0,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14.0,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        timeInfo,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textGrey,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8.0),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              title: Text(
                                'Hapus Obat',
                                style: GoogleFonts.inter(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // Show confirmation alert dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Hapus Obat'),
                                      content: Text(
                                        'Apakah Anda yakin ingin menghapus "$name"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteMedicine(medicineId);
                                          },
                                          child: const Text(
                                            'Hapus',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.medicalBlue,
                              ),
                              title: Text(
                                'Ubah Obat',
                                style: GoogleFonts.inter(
                                  color: AppColors.medicalBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UpdateMedicinePage(medicine: medicine),
                                  ),
                                );
                                if (result == true) {
                                  _loadMedicines();
                                }
                              },
                            ),
                            const SizedBox(height: 8.0),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
