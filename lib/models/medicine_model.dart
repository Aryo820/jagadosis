class MedicineModel {
  final String id;
  final String medicineName;
  final String dose;
  final String scheduleTime;

  /// Per-slot consumption status, stored comma-separated and kept parallel to
  /// [scheduleTime]. For a medicine taken twice a day the value looks like
  /// "taken, pending" — one token per scheduled time. Legacy rows that store a
  /// single token (e.g. "pending") are still read correctly via [slotStatuses].
  final String status;
  final bool enableNotification;

  /// When this medicine was first added. Used so a dose slot whose time had
  /// already passed *before* the medicine existed is not instantly marked as
  /// 'missed' — instead it starts from its next occurrence.
  final DateTime createdAt;

  MedicineModel({
    required this.id,
    required this.medicineName,
    required this.dose,
    required this.scheduleTime,
    required this.status,
    this.enableNotification = true,
    required this.createdAt,
  });

  /// Individual scheduled times, e.g. ["08:00", "20:00"].
  List<String> get scheduleTimes => scheduleTime
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Status of each scheduled time, parallel to [scheduleTimes].
  ///
  /// Normalises the stored [status] string so its length always matches the
  /// number of scheduled times:
  ///   * a single legacy token (e.g. "pending") is applied to every slot,
  ///   * a shorter list is padded with 'pending',
  ///   * a longer list is truncated.
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
    // Legacy single value → apply to all slots.
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

  /// Whether at least one scheduled time is still pending.
  bool get hasPendingSlot => slotStatuses.any((s) => s == 'pending');

  /// True when every scheduled time has been marked as taken.
  bool get isFullyTaken => slotStatuses.every((s) => s == 'taken');

  /// Builds the comma-separated [status] value from a list of slot statuses.
  static String joinStatuses(List<String> statuses) => statuses.join(', ');

  /// Returns a copy with the status of the slot at [index] changed to
  /// [newStatus], leaving all other slots untouched.
  MedicineModel copyWithSlotStatus(int index, String newStatus) {
    final statuses = slotStatuses;
    if (index < 0 || index >= statuses.length) return this;
    statuses[index] = newStatus;
    return copyWith(status: joinStatuses(statuses));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dose': dose,
      'scheduleTime': scheduleTime,
      'status': status,
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
      enableNotification: (map['enableNotification'] ?? 1) == 1,
      // Legacy rows without a createdAt are treated as created long ago so they
      // keep their normal 'missed' behaviour.
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
    bool? enableNotification,
    DateTime? createdAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dose: dose ?? this.dose,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      status: status ?? this.status,
      enableNotification: enableNotification ?? this.enableNotification,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
