import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class KomentarService {
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

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getKomentarByLaporan(int laporanId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/komentar/laporan/$laporanId"),
      headers: _headers(),
    );

    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      if (data is Map && data["data"] is List) {
        return data["data"];
      }

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(data["message"] ?? "Gagal mengambil komentar");
  }

  static Future<Map<String, dynamic>> tambahKomentar({
    required int laporanId,
    required int userId,
    required String komentar,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/komentar"),
      headers: _headers(token: token),
      body: jsonEncode({
        "laporan_id": laporanId,
        "user_id": userId,
        "komentar": komentar,
      }),
    );

    final data = _decodeBody(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data is Map<String, dynamic>) {
        return data["data"] ?? data;
      }

      return {};
    }

    throw Exception(data["message"] ?? data["error"] ?? "Gagal menambahkan komentar");
  }

  static Future<Map<String, dynamic>> editKomentar({
    required int komentarId,
    required String komentar,
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/komentar/$komentarId"),
      headers: _headers(token: token),
      body: jsonEncode({
        "komentar": komentar,
      }),
    );

    print("EDIT KOMENTAR STATUS: ${response.statusCode}");
    print("EDIT KOMENTAR BODY: ${response.body}");

    final data = _decodeBody(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data is Map<String, dynamic>) {
        return data["data"] ?? data;
      }

      return {};
    }

    throw Exception(
      data["message"] ?? data["error"] ?? "Gagal mengedit komentar",
    );
  }

  static Future<void> hapusKomentar({
    required int komentarId,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/komentar/$komentarId"),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;

    final data = _decodeBody(response);
    throw Exception(data["message"] ?? data["error"] ?? "Gagal menghapus komentar");
  }
}