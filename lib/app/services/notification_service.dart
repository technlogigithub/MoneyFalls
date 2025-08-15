import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../modules/bottom_bar/controllers/bottom_bar_controller.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;
  String? fcmToken;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();

    // Setup message handlers
    await _setupMessageHandlers();

    // Get FCM token safely
    String? token = await _messaging.getToken();
    if (token != null) {
      fcmToken = token;
      print('FCM Token: $fcmToken'); // Ensures token is fetched before use
    } else {
      print('Failed to get FCM token');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    // android setup
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
    AndroidInitializationSettings('icon');

    // ios setup
    final initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: (id, title, body, payload) async {
      //   // Handle iOS foreground notification
      // },
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // flutter notification setup
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
            'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'icon',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    //foreground message
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    // background message
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // opened app
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  // void _handleBackgroundMessage(RemoteMessage message) {
  //   final data = message.data;
  //   print('Notification clicked with data: $data');
  //   print('now data type ${data['type']}');
  //
  //   if (data['type'] == 'chat') {
  //
  //     // Use GetX navigation if app is running
  //     if (Get.isRegistered<BottomBarController>()) {
  //       Get.offAllNamed('/bottom-bar');
  //       final bottomBarController = Get.find<BottomBarController>();
  //       bottomBarController.currentIndex.value = 3; // Favourite tab index
  //       bottomBarController.onTapChange(bottomBarController.currentIndex.value);
  //     }
  //     // if (Get.isRegistered<GetMaterialApp>()) {
  //     //   Get.toNamed('/favourite', arguments: {
  //     //     'chatRoomId': chatRoomId,
  //     //     'userName': userName,
  //     //     'userImage': userImage,
  //     //   });
  //     // }
  //     else {
  //       // Fallback: use navigatorKey for terminated case
  //       Get.offAllNamed('/bottom-bar');
  //       final bottomBarController = Get.put(BottomBarController());
  //       bottomBarController.currentIndex.value = 3; // Favourite tab index
  //       bottomBarController.onTapChange(bottomBarController.currentIndex.value);
  //       // navigatorKey.currentState?.pushNamed(
  //       //   '/bottom-bar',
  //       // );
  //       //
  //       // navigatorKey.currentState?.pushNamed(
  //       //   '/favourite',
  //       //   arguments: {
  //       //     'chatRoomId': chatRoomId,
  //       //     'userName': userName,
  //       //     'userImage': userImage,
  //       //   },
  //       // );
  //     }
  //   }
  // }

  void _handleBackgroundMessage(RemoteMessage message) async {
    final data = message.data;
    print('Notification clicked with data: $data');

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in. Redirecting to login.');
      Get.offAllNamed('/login'); // or your login route
      return;
    }

    if (data['type'] == 'chat') {
      iscommingFromNotification = true;
      Get.offAllNamed('/bottom-bar');

      // Delay to ensure BottomBarController is ready
      Future.delayed(const Duration(seconds: 1), () {
        if (Get.isRegistered<BottomBarController>()) {
          final bottomBarController = Get.find<BottomBarController>();
          bottomBarController.currentIndex.value = 3; // Navigate to chat tab
        }
      });
    }
  }


}