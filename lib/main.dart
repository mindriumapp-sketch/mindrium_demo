import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/notification_provider.dart';
import 'package:gad_app_team/app.dart'; // Mindrium 전체 라우팅 포함

/// 🌊 Mindrium 앱 시작점 (Provider 초기화)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Rive 초기화
  await RiveNative.init();

  // ✅ 전역 Provider 구성
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserDayCounter()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
