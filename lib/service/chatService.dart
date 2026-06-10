import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ChatService {
  static Future<Map<String, dynamic>> getOrCreateRoom({
    required int userId,
    required int adminId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chat/room"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "user_id": userId,
        "admin_id": adminId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data["data"];
    }

    throw Exception(data["message"] ?? "Gagal membuat room chat");
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int roomId,
    required int senderId,
    required String message,
    int? referenceLaporanId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chat/message"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "room_id": roomId,
        "sender_id": senderId,
        "message": message,
        "reference_laporan_id": referenceLaporanId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data["data"];
    }

    throw Exception(data["message"] ?? "Gagal mengirim pesan");
  }

  static Future<List<dynamic>> getMessagesByRoom(int roomId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/chat/messages/$roomId"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    }

    throw Exception(data["message"] ?? "Gagal mengambil pesan");
  }

  static Future<void> markMessagesAsRead({
    required int roomId,
    required int userId,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/chat/messages/$roomId/read"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "user_id": userId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Gagal menandai pesan dibaca");
    }
  }

  static Future<List<dynamic>> getChatRoomsByUser(int userId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/chat/rooms/user/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    }

    throw Exception(data["message"] ?? "Gagal mengambil daftar chat");
  }
}