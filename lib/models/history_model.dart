class HistoryModel {
  final String id;
  final String medicineName;
  final DateTime takenAt; // Waktu ketika obat dikonsumsi
  final String status;    // Status konsumsi obat (misal: 'taken', 'missed')

  // Constructor dengan parameter wajib (required) dan aman (null safety)
  HistoryModel({
    required this.id,
    required this.medicineName,
    required this.takenAt,
    required this.status,
  });

  // Mengubah object HistoryModel menjadi Map.
  // DateTime diubah menjadi format String ISO 8601 agar bisa disimpan di database/JSON.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'takenAt': takenAt.toIso8601String(),
      'status': status,
    };
  }

  // Membuat instance HistoryModel dari Map.
  // String ISO 8601 di-parse kembali menjadi object DateTime.
  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] ?? '',
      medicineName: map['medicineName'] ?? '',
      takenAt: map['takenAt'] != null
          ? DateTime.parse(map['takenAt'])
          : DateTime.now(), // Fallback ke waktu sekarang jika null
      status: map['status'] ?? '',
    );
  }
}
