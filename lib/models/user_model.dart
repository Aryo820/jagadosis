class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;

  // Constructor dengan parameter wajib (required) dan aman (null safety)
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Mengubah object UserModel menjadi Map (format key-value), biasanya digunakan untuk database SQLite atau API
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }

  // Membuat instance UserModel dari Map (misalnya data dari database SQLite atau API)
  // Dilengkapi dengan nilai default (fallback) jika data di map bernilai null
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }
}
