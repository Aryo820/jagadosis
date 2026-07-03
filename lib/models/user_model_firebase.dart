import 'package:aplikasi/models/user_model.dart';

class UserModelFirebase {
  final String id;
  final String name;
  final String email;
  final String password;

  UserModelFirebase({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }

  factory UserModelFirebase.fromMap(Map<String, dynamic> map) {
    return UserModelFirebase(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }

  factory UserModelFirebase.fromUserModel(UserModel user) {
    return UserModelFirebase(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
    );
  }

  UserModel toUserModel() {
    return UserModel(id: id, name: name, email: email, password: password);
  }
}
