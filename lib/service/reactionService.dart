import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ReactionService {
  static Map<String, String> _headers({String? token}) {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static Future<Map<String, dynamic>> getReactionCount({
    required int laporanId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/reactions/laporan/$laporanId"),
      headers: _headers(token: token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? data;
    }

    throw Exception(data["message"] ?? "Gagal mengambil reaction");
  }

  static Future<void> likeLaporan({
    required int laporanId,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/reactions/laporan/$laporanId/like"),
      headers: _headers(token: token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data["message"] ?? "Gagal memberikan like");
    }
  }

  static Future<void> dislikeLaporan({
    required int laporanId,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/reactions/laporan/$laporanId/dislike"),
      headers: _headers(token: token),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data["message"] ?? "Gagal memberikan dislike");
    }
  }

  static Future<void> deleteReaction({
    required int laporanId,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/reactions/laporan/$laporanId"),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;

    final data = jsonDecode(response.body);
    throw Exception(data["message"] ?? "Gagal menghapus reaction");
  }
}