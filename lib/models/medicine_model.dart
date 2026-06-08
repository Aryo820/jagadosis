class MedicineModel {
  final String id;
  final String medicineName;
  final String dose;
  final String scheduleTime;
  final String status; // Status obat: 'taken', 'missed', atau 'pending'

  // Constructor dengan parameter wajib (required) dan aman (null safety)
  MedicineModel({
    required this.id,
    required this.medicineName,
    required this.dose,
    required this.scheduleTime,
    required this.status,
  });

  // Mengubah object MedicineModel menjadi Map untuk mempermudah penyimpanan lokal (SQLite/SharedPref) atau API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dose': dose,
      'scheduleTime': scheduleTime,
      'status': status,
    };
  }

  // Membuat instance MedicineModel dari Map dengan fallback nilai default jika data null
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dose: map['dose'] ?? '',
      scheduleTime: map['scheduleTime'] ?? '',
      status: map['status'] ?? 'pending', // Default status adalah pending
    );
  }
}
