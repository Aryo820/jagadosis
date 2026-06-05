import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JagaDosis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.medicalBlue,
          primary: AppColors.medicalBlue,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
