import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:aplikasi/database/preference_handler.dart';
import 'package:aplikasi/firebase_options.dart';
import 'package:aplikasi/screens/alarm/alarm_ring_page.dart';
import 'package:aplikasi/screens/auth/login_page.dart';
import 'package:aplikasi/screens/dashboard_page.dart';
import 'package:aplikasi/screens/splash/splash_screen.dart';
import 'package:aplikasi/services/alarm_service.dart';
import 'package:aplikasi/services/notification_service.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Navigator key global agar layar alarm berbunyi bisa ditampilkan dari
/// listener Alarm.ringing di level teratas, tanpa bergantung pada rute yang
/// sedang aktif.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferenceHandler.init();

  // Inisialisasi notifikasi (sekaligus menyiapkan subsistem alarm berbunyi),
  // lalu jadwalkan ulang pengingat HANYA jika sesi login sudah dipulihkan.
  // Data obat sekarang disimpan di Firestore berdasarkan uid pengguna, jadi
  // tidak ada yang perlu dijadwalkan sampai kita tahu siapa yang sedang login.
  // Tunggu status auth pertama (dibatasi waktu, untuk jaga-jaga jika pemulihan
  // sesi macet saat offline).
  final notificationService = NotificationService();
  await notificationService.init();

  final initialUser = await FirebaseAuth.instance
      .authStateChanges()
      .first
      .timeout(const Duration(seconds: 5), onTimeout: () => null);
  // Lewati penjadwalan ulang saat startup jika ada alarm yang sedang berbunyi —
  // misalnya aplikasi baru dibuka dari nol karena pengguna menekan notifikasi
  // alarm layar penuh. Jika tidak dilewati, Alarm.stopAll() di dalam
  // rescheduleAll() akan mematikan alarm itu sebelum layar alarm sempat muncul.
  // Listener alarm tetap menampilkannya, dan layar alarm menjadwalkan ulang
  // slotnya setelah pengguna bertindak (ini hanya melewati satu proses startup).
  if (initialUser != null && !await Alarm.isRinging()) {
    await notificationService.rescheduleAll();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Generic tanpa tipe eksplisit: Alarm.ringing mengeluarkan AlarmSet internal
  // milik package yang tidak diekspor. Penentuan tipe di dalam listener yang
  // menanganinya.
  StreamSubscription<Object?>? _ringSubscription;

  /// Kumpulan ID alarm yang sedang berbunyi, supaya setiap alarm baru hanya
  /// menampilkan layarnya tepat satu kali (stream memancarkan ulang seluruh set
  /// setiap ada perubahan).
  Set<int> _ringingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Saat sebuah alarm berbunyi, tampilkan UI alarm layar penuh. Memakai
    // navigator key global agar tetap berfungsi apa pun layar yang sedang aktif
    // (atau jika aplikasi dibuka dari intent layar penuh milik alarm).
    _ringSubscription = Alarm.ringing.listen((alarmSet) {
      for (final settings in alarmSet.alarms) {
        if (_ringingIds.contains(settings.id)) continue;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AlarmRingPage(settings: settings),
          ),
        );
      }
      _ringingIds = alarmSet.alarms.map((a) => a.id).toSet();
    });
  }

  @override
  void dispose() {
    _ringSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pengaman untuk pengulangan harian: jadwalkan ulang alarm yang akan datang
    // setiap aplikasi kembali ke depan (foreground), supaya tidak ada hari yang
    // terlewat jika aplikasi sempat dimatikan paksa.
    //
    // Dilewati saat ada alarm berbunyi: rescheduleAll() memanggil
    // Alarm.stopAll(), yang akan mematikan alarm yang justru sedang ingin dijawab
    // pengguna saat membuka aplikasi. Listener alarm sudah mengisi _ringingIds
    // sebelum kita resume, dan layar alarm menjadwalkan ulang slotnya sendiri
    // begitu pengguna bertindak.
    if (state == AppLifecycleState.resumed && _ringingIds.isEmpty) {
      AlarmService().rescheduleAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JagaDosis',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
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
      // home: const SplashScreen(), // (dinonaktifkan) alternatif memakai home langsung
    );
  }
}
