import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery/app/services/notification_service.dart';
import 'package:lottery/app/services/user_data.dart';
import 'app/app.dart';
import 'app/services/online_offline_service.dart';
import 'firebase_options.dart';
import 'package:device_info_plus/device_info_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool iscommingFromNotification = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  checkInstaller();
  Get.put(UserStatusService());
  Get.put(UserController());
  await NotificationService.instance.initialize();

  // print('Another check ${NotificationService.instance.fcmToken}');

  runApp(App());
}

void checkInstaller() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  log("Installer Package: ${androidInfo.name}");
}
