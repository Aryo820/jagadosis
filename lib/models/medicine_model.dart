class MedicineModel {
  final String id;
  final String medicineName;
  final String dose;
  final String scheduleTime;

  /// Status konsumsi untuk tiap slot waktu, disimpan dipisah koma dan sejajar
  /// dengan [scheduleTime]. Untuk obat yang diminum dua kali sehari nilainya
  /// seperti "taken, pending" — satu token untuk tiap jadwal. Data lama yang
  /// hanya menyimpan satu token (misal "pending") tetap terbaca benar lewat
  /// [slotStatuses].
  final String status;
  final String statusDate;
  final bool enableNotification;

  /// Waktu obat ini pertama kali ditambahkan. Dipakai agar slot dosis yang
  /// jamnya sudah lewat *sebelum* obat dibuat tidak langsung ditandai 'missed'
  /// (terlewat) — melainkan dihitung mulai dari jadwal berikutnya.
  final DateTime createdAt;

  MedicineModel({
    required this.id,
    required this.medicineName,
    required this.dose,
    required this.scheduleTime,
    required this.status,
    required this.statusDate,
    this.enableNotification = true,
    required this.createdAt,
  });

  /// Daftar jam jadwal satu per satu, misal ["08:00", "20:00"].
  List<String> get scheduleTimes => scheduleTime
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  static String dateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')
        .first;
  }

  /// Status untuk tiap jam jadwal, sejajar dengan [scheduleTimes].
  ///
  /// Menormalkan string [status] yang tersimpan agar jumlahnya selalu sama
  /// dengan jumlah jam jadwal:
  ///   * satu token lama (misal "pending") diterapkan ke semua slot,
  ///   * daftar yang lebih pendek ditambahi 'pending',
  ///   * daftar yang lebih panjang dipotong.
  List<String> get slotStatuses {
    final times = scheduleTimes;
    final slotCount = times.isEmpty ? 1 : times.length;

    final raw = status
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (raw.isEmpty) {
      return List.filled(slotCount, 'pending');
    }
    // Nilai lama yang cuma satu → terapkan ke semua slot.
    if (raw.length == 1 && slotCount > 1) {
      return List.filled(slotCount, raw.first);
    }
    if (raw.length < slotCount) {
      return [...raw, ...List.filled(slotCount - raw.length, 'pending')];
    }
    if (raw.length > slotCount) {
      return raw.sublist(0, slotCount);
    }
    return raw;
  }

  /// Bernilai true jika masih ada minimal satu jadwal yang berstatus pending.
  bool get hasPendingSlot => slotStatuses.any((s) => s == 'pending');

  /// Bernilai true jika semua jadwal sudah ditandai taken (sudah diminum).
  bool get isFullyTaken => slotStatuses.every((s) => s == 'taken');

  /// Menyusun nilai [status] yang dipisah koma dari daftar status tiap slot.
  static String joinStatuses(List<String> statuses) => statuses.join(', ');

  bool get isStatusForToday => statusDate == dateKey(DateTime.now());

  MedicineModel resetDailyStatus({DateTime? date}) {
    final slotCount = scheduleTimes.isEmpty ? 1 : scheduleTimes.length;
    return copyWith(
      status: joinStatuses(List.filled(slotCount, 'pending')),
      statusDate: dateKey(date ?? DateTime.now()),
    );
  }

  /// Mengembalikan salinan objek dengan status slot pada [index] diubah menjadi
  /// [newStatus], sedangkan slot lainnya tetap tidak berubah.
  MedicineModel copyWithSlotStatus(int index, String newStatus) {
    final statuses = slotStatuses;
    if (index < 0 || index >= statuses.length) return this;
    statuses[index] = newStatus;
    return copyWith(
      status: joinStatuses(statuses),
      statusDate: dateKey(DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dose': dose,
      'scheduleTime': scheduleTime,
      'status': status,
      'statusDate': statusDate,
      'enableNotification': enableNotification ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dose: map['dose'] ?? '',
      scheduleTime: map['scheduleTime'] ?? '',
      status: map['status'] ?? 'pending',
      statusDate:
          (map['statusDate'] != null &&
              (map['statusDate'] as String).isNotEmpty)
          ? map['statusDate']
          : dateKey(DateTime.fromMillisecondsSinceEpoch(0)),
      enableNotification: (map['enableNotification'] ?? 1) == 1,
      // Data lama tanpa createdAt dianggap dibuat sejak lama, supaya perilaku
      // 'missed' (terlewat) tetap berjalan normal.
      createdAt: (map['createdAt'] != null &&
              (map['createdAt'] as String).isNotEmpty)
          ? DateTime.parse(map['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  MedicineModel copyWith({
    String? id,
    String? medicineName,
    String? dose,
    String? scheduleTime,
    String? status,
    String? statusDate,
    bool? enableNotification,
    DateTime? createdAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dose: dose ?? this.dose,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      status: status ?? this.status,
      statusDate: statusDate ?? this.statusDate,
      enableNotification: enableNotification ?? this.enableNotification,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
