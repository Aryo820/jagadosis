import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/firebase_options.dart';
import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/screens/dashboard_page.dart';
import 'package:aplikasi/screens/splash/splash_screen.dart';
import 'package:aplikasi/services/notification_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferenceHandler.init();

  // Initialize notification service and reschedule existing reminders
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.rescheduleAll();

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
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/dashboard': (context) => DashboardPage(),
      },
      // home: const SplashScreen(),
    );
  }
}
