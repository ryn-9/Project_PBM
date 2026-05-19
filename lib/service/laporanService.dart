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
}