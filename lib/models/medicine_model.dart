class MedicineModel {
  final String id;
  final String medicineName;
  final String dose;
  final String scheduleTime;
  final String status;
  final bool enableNotification;

  MedicineModel({
    required this.id,
    required this.medicineName,
    required this.dose,
    required this.scheduleTime,
    required this.status,
    this.enableNotification = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dose': dose,
      'scheduleTime': scheduleTime,
      'status': status,
      'enableNotification': enableNotification ? 1 : 0,
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
    );
  }

  MedicineModel copyWith({
    String? id,
    String? medicineName,
    String? dose,
    String? scheduleTime,
    String? status,
    bool? enableNotification,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dose: dose ?? this.dose,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      status: status ?? this.status,
      enableNotification: enableNotification ?? this.enableNotification,
    );
  }
}
