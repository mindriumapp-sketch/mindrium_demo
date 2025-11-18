import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import 'package:gad_app_team/firebase_options.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/notification_provider.dart';
<<<<<<< HEAD
import 'package:gad_app_team/data/screen_time_provider.dart';
import 'package:gad_app_team/data/screen_time_auto_tracker.dart';
import 'package:gad_app_team/app.dart'; // Mindrium 전체 라우팅 포함
=======
import 'package:gad_app_team/app.dart'; // Mindrium 전체 라우팅 포함
import 'package:gad_app_team/data/screen_time_provider.dart';
import 'package:gad_app_team/data/screen_time_auto_tracker.dart';
>>>>>>> 7cf0a32 (1118 통합)

/// 🌊 Mindrium 앱 시작점 (Firebase + Provider 초기화)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Rive 초기화
  await RiveNative.init();
 
  // ✅ 전역 Provider 구성
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserDayCounter()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ScreenTimeProvider()),
        ChangeNotifierProxyProvider<ScreenTimeProvider, ScreenTimeAutoTracker>(
          create: (context) => ScreenTimeAutoTracker(
            provider: context.read<ScreenTimeProvider>(),
          ),
          update: (context, screenTime, tracker) {
            tracker?.updateProvider(screenTime);
            return tracker ?? ScreenTimeAutoTracker(provider: screenTime);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}
