import 'dart:convert';
import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String relation;
  final String phone;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'phone': phone,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<EmergencyContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final jsonStr = PreferenceHandler.emergencyContacts;
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      setState(() {
        _contacts = decoded.map((item) => EmergencyContact.fromMap(item)).toList();
      });
    } catch (e) {
      setState(() {
        _contacts = [];
      });
    }
  }

  Future<void> _saveContacts() async {
    final List<Map<String, dynamic>> mapped = _contacts.map((c) => c.toMap()).toList();
    final jsonStr = jsonEncode(mapped);
    await PreferenceHandler.saveEmergencyContacts(jsonStr);
  }

  void _callNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Tidak dapat melakukan panggilan';
      }
    } catch (e) {
      // Fallback: Copy to clipboard and notify
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nomor $phoneNumber telah disalin ke papan klip',
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
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final isEdit = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationController = TextEditingController(text: contact?.relation ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Ubah Kontak' : 'Tambah Kontak Baru',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.inter(color: AppColors.textDark),
                  decoration: _buildInputDecoration(label: 'Nama Lengkap', icon: Icons.person_outline_rounded),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationController,
                  style: GoogleFonts.inter(color: AppColors.textDark),
                  decoration: _buildInputDecoration(label: 'Hubungan (misal: Ibu, Dokter)', icon: Icons.people_outline_rounded),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: AppColors.textDark),
                  decoration: _buildInputDecoration(label: 'Nomor Telepon', icon: Icons.phone_android_rounded),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final relation = relationController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || relation.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Semua bidang harus diisi', style: GoogleFonts.inter()),
                      backgroundColor: const Color(0xFFEB5757),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (isEdit) {
                    final index = _contacts.indexWhere((c) => c.id == contact.id);
                    if (index != -1) {
                      _contacts[index] = EmergencyContact(
                        id: contact.id,
                        name: name,
                        relation: relation,
                        phone: phone,
                      );
                    }
                  } else {
                    _contacts.add(
                      EmergencyContact(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        relation: relation,
                        phone: phone,
                      ),
                    );
                  }
                });

                await _saveContacts();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medicalBlue,
                foregroundColor: AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isEdit ? 'Simpan' : 'Tambah',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteContact(String id) async {
    setState(() {
      _contacts.removeWhere((c) => c.id == id);
    });
    await _saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      appBar: AppBar(
        title: Text(
          'Kontak Darurat',
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
      body: _contacts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildContactCard(contact),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        backgroundColor: AppColors.medicalBlue,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Tambah Kontak',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEB5757).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_outlined,
                color: Color(0xFFEB5757),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada Kontak Darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daftarkan nomor telepon keluarga dekat atau dokter Anda agar mudah dihubungi saat situasi penting.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    // Generate color based on relationship
    final isMedical = contact.relation.toLowerCase().contains('dok') || 
                      contact.relation.toLowerCase().contains('rs') || 
                      contact.relation.toLowerCase().contains('sakit');
    final badgeColor = isMedical ? AppColors.wellnessGreen : const Color(0xFFEB5757);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar Initial
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          contact.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          contact.relation,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phone,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call
                IconButton(
                  onPressed: () => _callNumber(contact.phone),
                  icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.medicalBlue),
                  tooltip: 'Hubungi',
                ),
                // Menu (Edit/Delete)
                PopupMenuButton<String>(
                  color: AppColors.surfaceWhite,
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textGrey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showContactDialog(contact: contact);
                    } else if (value == 'delete') {
                      _showDeleteConfirm(contact);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18, color: AppColors.textGrey),
                          const SizedBox(width: 8),
                          Text('Ubah', style: GoogleFonts.inter(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEB5757)),
                          const SizedBox(width: 8),
                          Text('Hapus', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFEB5757))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Hapus Kontak?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus ${contact.name} dari daftar kontak darurat?',
            style: GoogleFonts.inter(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
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
                _deleteContact(contact.id);
                Navigator.pop(context);
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

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.medicalBlue, size: 20),
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
