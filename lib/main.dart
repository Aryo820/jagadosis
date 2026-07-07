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

/// Global navigator key so the alarm ring screen can be pushed from the
/// top-level Alarm.ringing listener, independent of the current route.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferenceHandler.init();

  // Initialize notifications (which also initializes the ringing-alarm
  // subsystem), then reschedule reminders only when a session is already
  // restored — medicines now live in Firestore under the user's uid, so there's
  // nothing to schedule until we know who is signed in. Wait for the first auth
  // state (bounded, in case restoration stalls offline).
  final notificationService = NotificationService();
  await notificationService.init();

  final initialUser = await FirebaseAuth.instance
      .authStateChanges()
      .first
      .timeout(const Duration(seconds: 5), onTimeout: () => null);
  // Skip the startup reschedule while an alarm is already ringing — e.g. the app
  // was cold-started by tapping the alarm's full-screen notification. Otherwise
  // rescheduleAll()'s Alarm.stopAll() would silence that alarm before the ring
  // screen even appears. The ring listener still shows it, and the ring screen
  // re-arms the slot after the user acts (this only skips the one startup pass).
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
  // Untyped generic: Alarm.ringing emits the package's internal AlarmSet, which
  // isn't exported. Type inference in the listener handles it.
  StreamSubscription<Object?>? _ringSubscription;

  /// Ids currently ringing, so each new ring pushes the screen exactly once
  /// (the stream re-emits the whole set on every change).
  Set<int> _ringingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // When an alarm fires, bring up the full-screen ring UI. Uses the global
    // navigator key so it works regardless of which screen is on top (or if the
    // app was launched from the alarm's full-screen intent).
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
    // Safety net for daily recurrence: re-arm upcoming alarms whenever the app
    // returns to the foreground, so days aren't skipped if the app was killed.
    //
    // Skip while an alarm is ringing: rescheduleAll() calls Alarm.stopAll(),
    // which would silence the alarm the user just opened the app to answer. The
    // ring listener has already populated _ringingIds by the time we resume, and
    // the ring screen re-arms that slot itself once the user acts.
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
      // home: const SplashScreen(),
    );
  }
}
