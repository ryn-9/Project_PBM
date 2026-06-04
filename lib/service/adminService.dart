import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  static const String baseUrl = "https://wadulguse-api.vercel.app/api";

  static Future<Map<String, dynamic>> getStatistikAdmin() async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/statistik"),
      headers: {
        "accept": "*/*",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body["data"];
    } else {
      throw Exception(body["message"] ?? "Gagal mengambil statistik admin");
    }
  }

  static Future<List<dynamic>> getAllLaporan() async {
    final response = await http.get(
      Uri.parse("$baseUrl/laporan"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (body is List) {
        return body;
      }

      if (body["data"] is List) {
        return body["data"];
      }

      return [];
    } else {
      throw Exception(body["message"] ?? "Gagal mengambil daftar laporan");
    }
  }

  static Future<void> updateStatusLaporan({
    required int laporanId,
    required String status,
    required String catatan,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/laporan/$laporanId/status"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "status": status,
        "catatan_admin": catatan,
      }),
    );

    print("UPDATE STATUS URL: $baseUrl/laporan/$laporanId/status");
    print("UPDATE STATUS CODE: ${response.statusCode}");
    print("UPDATE STATUS BODY: ${response.body}");

    if (response.statusCode != 200) {
      String errorMessage = "Gagal memperbarui laporan";

      try {
        final body = jsonDecode(response.body);
        errorMessage = body["message"] ?? errorMessage;
      } catch (_) {
        errorMessage = "Server mengembalikan response bukan JSON";
      }

      throw Exception(errorMessage);
    }
  }
}