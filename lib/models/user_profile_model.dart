/// The user's personal & medical profile, stored per-user in Firestore under
/// `users/{uid}` and mirrored into local SharedPreferences for offline reads.
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

  /// The privacy-policy and terms-&-conditions versions the user agreed to at
  /// registration, and the ISO-8601 timestamp when they agreed (both are
  /// accepted together via a single checkbox). Empty for accounts created
  /// before consent was recorded.
  final String consentVersion;
  final String termsVersion;
  final String consentAcceptedAt;

  /// Builds a profile from a Firestore document's data map. Missing fields
  /// default to empty strings so a partially-filled document never throws.
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

  /// Serialises to a Firestore-writable map. `updatedAt` is added by the
  /// repository (it uses a server timestamp sentinel, not a plain value).
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
