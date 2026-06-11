import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'active_chat_service.dart';

class FcmChatService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    'chat_channel',
    'Chat Notifications',
    description: 'Notifikasi pesan chat masuk',
    importance: Importance.high,
  );

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _initLocalNotification();
    _listenForegroundMessage();
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _initLocalNotification() async {
    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);
  }

  static void _listenForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;

      final type = data["type"]?.toString();

      if (type != "chat") return;

      final int? roomId = int.tryParse(
        data["room_id"]?.toString() ?? "",
      );

      if (roomId != null && ActiveChatService.activeRoomId == roomId) {
        print("Chat room sedang dibuka, notif tidak ditampilkan");
        return;
      }

      final title = message.notification?.title ?? "Pesan Baru";
      final body = message.notification?.body ?? "Ada pesan chat masuk";

      await showLocalChatNotification(
        title: title,
        body: body,
      );
    });
  }

  static Future<void> showLocalChatNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifikasi pesan chat masuk',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}