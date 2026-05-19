import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("role", data["role"]);
      await prefs.setString("nama", data["nama"] ?? "");

      return data;
    } else {
      throw Exception(data["message"] ?? "Login gagal");
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  static Future<Map<String, dynamic>> register({
  required String nama,
  required String email,
  required String password,
  required String noHp,
}) async {
  final response = await http.post(
    Uri.parse("${ApiConfig.baseUrl}/auth/register"),
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: jsonEncode({
      "nama": nama,
      "email": email,
      "password": password,
      "no_hp": noHp,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return data;
  } else {
    throw Exception(data["message"] ?? "Register gagal");
  }
}
}