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
      // A record with no/invalid takenAt is corrupt; its real time is unknown.
      // Fall back to the Unix epoch (a clear sentinel) rather than DateTime.now(),
      // which would silently stamp the record with the read time and misplace it
      // as "just taken" in history and adherence stats.
      takenAt: _parseTakenAt(map['takenAt']),
      status: map['status'] ?? '',
    );
  }

  /// Parses an ISO-8601 `takenAt`, tolerating null or malformed values by
  /// returning the Unix epoch as an explicit "unknown time" sentinel.
  static DateTime _parseTakenAt(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
