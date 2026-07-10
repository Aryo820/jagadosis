/// Profil pribadi & medis pengguna, disimpan per pengguna di Firestore pada
/// `users/{uid}` dan disalin ke SharedPreferences lokal agar bisa dibaca saat
/// offline.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.birthDate = '',
    this.gender = '',
    this.bloodType = '',
    this.allergies = '',
    this.consentVersion = '',
    this.termsVersion = '',
    this.consentAcceptedAt = '',
  });

  final String name;
  final String email;
  final String birthDate;
  final String gender;
  final String bloodType;
  final String allergies;

  /// Versi kebijakan privasi dan syarat & ketentuan yang disetujui pengguna saat
  /// registrasi, beserta timestamp ISO-8601 kapan disetujui (keduanya disetujui
  /// sekaligus lewat satu checkbox). Kosong untuk akun yang dibuat sebelum
  /// persetujuan mulai dicatat.
  final String consentVersion;
  final String termsVersion;
  final String consentAcceptedAt;

  /// Membentuk profil dari map data dokumen Firestore. Field yang tidak ada
  /// diberi nilai default string kosong, sehingga dokumen yang belum lengkap
  /// tidak pernah menyebabkan error.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      birthDate: (map['birthDate'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? '',
      bloodType: (map['bloodType'] as String?) ?? '',
      allergies: (map['allergies'] as String?) ?? '',
      consentVersion: (map['consentVersion'] as String?) ?? '',
      termsVersion: (map['termsVersion'] as String?) ?? '',
      consentAcceptedAt: (map['consentAcceptedAt'] as String?) ?? '',
    );
  }

  /// Mengubah profil menjadi map yang bisa ditulis ke Firestore. Field
  /// `updatedAt` ditambahkan oleh repository (memakai penanda timestamp server,
  /// bukan nilai biasa).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'birthDate': birthDate,
      'gender': gender,
      'bloodType': bloodType,
      'allergies': allergies,
      'consentVersion': consentVersion,
      'termsVersion': termsVersion,
      'consentAcceptedAt': consentAcceptedAt,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? birthDate,
    String? gender,
    String? bloodType,
    String? allergies,
    String? consentVersion,
    String? termsVersion,
    String? consentAcceptedAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      consentVersion: consentVersion ?? this.consentVersion,
      termsVersion: termsVersion ?? this.termsVersion,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
    );
  }
}
