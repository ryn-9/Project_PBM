import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LaporanService {
  static Future<List<dynamic>> getLaporanPublic() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/laporan/public"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    } else {
      throw Exception(data["message"] ?? "Gagal mengambil laporan publik");
    }
  }

  static Future<List<dynamic>> getLaporanByUser(int userId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/laporan/user/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    } else {
      throw Exception(data["message"] ?? "Gagal mengambil laporan user");
    }
  }

  static Future<List<dynamic>> getRiwayatLaporanSelesaiByUser(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/laporan/user/$userId/selesai"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    } else {
      throw Exception(data["message"] ?? "Gagal mengambil riwayat laporan");
    }
  }

  static Future<Map<String, dynamic>> updateLaporan({
    required int laporanId,
    required int userId,
    required String judul,
    required String deskripsi,
    required String jenisLaporan,
    required double? latitude,
    required double? longitude,
    required String alamat,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/laporan/$laporanId"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "user_id": userId,
        "judul": judul,
        "deskripsi": deskripsi,
        "jenis_laporan": jenisLaporan,
        "latitude": latitude,
        "longitude": longitude,
        "alamat": alamat,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Gagal update laporan");
    }
  }
}