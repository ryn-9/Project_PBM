// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ChatNotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static RealtimeChannel? _chatNotifChannel;

//   static int? activeRoomId;
//   static int? currentUserId;

//   static const AndroidNotificationChannel _channel =
//       AndroidNotificationChannel(
//     'chat_channel',
//     'Chat Notifications',
//     description: 'Notifikasi pesan chat masuk',
//     importance: Importance.high,
//   );

//   static Future<void> init({
//     required int userId,
//   }) async {
//     currentUserId = userId;

//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

//     const initSettings = InitializationSettings(
//       android: androidInit,
//     );

//     await _notifications.initialize(initSettings);

//     await _notifications
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);

//     _subscribeChatNotification();
//   }

//   static void _subscribeChatNotification() {
//     if (currentUserId == null) return;

//     if (_chatNotifChannel != null) {
//       Supabase.instance.client.removeChannel(_chatNotifChannel!);
//     }

//     _chatNotifChannel = Supabase.instance.client
//         .channel("global_chat_notif_$currentUserId")
//         .onPostgresChanges(
//           event: PostgresChangeEvent.insert,
//           schema: "public",
//           table: "chat_messages",
//           callback: (payload) async {
//             final data = payload.newRecord;

//             final int senderId = _toInt(data["sender_id"]);
//             final int roomId = _toInt(data["room_id"]);
//             final String message = data["message"]?.toString() ?? "";

//             if (senderId == 0 || roomId == 0) return;

//             // Jangan notif kalau pesan dari diri sendiri
//             if (senderId == currentUserId) return;

//             // Jangan notif kalau room chat sedang dibuka
//             if (activeRoomId == roomId) return;

//             await showChatNotification(
//               title: "Pesan Baru",
//               body: message.isEmpty ? "Ada pesan masuk" : message,
//             );
//           },
//         )
//         .subscribe();
//   }

//   static Future<void> showChatNotification({
//     required String title,
//     required String body,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'chat_channel',
//       'Chat Notifications',
//       channelDescription: 'Notifikasi pesan chat masuk',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );

//     await _notifications.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title,
//       body,
//       notificationDetails,
//     );
//   }

//   static int _toInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     return int.tryParse(value.toString()) ?? 0;
//   }

//   static Future<void> dispose() async {
//     if (_chatNotifChannel != null) {
//       await Supabase.instance.client.removeChannel(_chatNotifChannel!);
//       _chatNotifChannel = null;
//     }
//   }
// }