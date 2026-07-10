class HistoryModel {
  final String id;
  final String medicineName;
  final DateTime takenAt; // Waktu saat obat dikonsumsi
  final String status;    // Status konsumsi obat (misal: 'taken' = diminum, 'missed' = terlewat)

  // Constructor dengan parameter wajib (required) dan aman terhadap null (null safety)
  HistoryModel({
    required this.id,
    required this.medicineName,
    required this.takenAt,
    required this.status,
  });

  // Mengubah objek HistoryModel menjadi Map.
  // DateTime diubah ke format String ISO 8601 supaya bisa disimpan di database/JSON.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'takenAt': takenAt.toIso8601String(),
      'status': status,
    };
  }

  // Membuat instance HistoryModel dari Map.
  // String ISO 8601 di-parse kembali menjadi objek DateTime.
  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] ?? '',
      medicineName: map['medicineName'] ?? '',
      // Data dengan takenAt kosong/tidak valid berarti rusak; waktu aslinya
      // tidak diketahui. Gunakan Unix epoch (penanda yang jelas) sebagai gantinya,
      // bukan DateTime.now(), sebab itu akan diam-diam mencap data dengan waktu
      // saat dibaca dan salah menempatkannya sebagai "baru diminum" pada riwayat
      // maupun statistik kepatuhan.
      takenAt: _parseTakenAt(map['takenAt']),
      status: map['status'] ?? '',
    );
  }

  /// Mem-parse `takenAt` berformat ISO-8601. Jika nilainya null atau rusak,
  /// mengembalikan Unix epoch sebagai penanda eksplisit "waktu tidak diketahui".
  static DateTime _parseTakenAt(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
