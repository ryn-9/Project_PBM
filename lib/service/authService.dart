import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", data["token"] ?? "");
      await prefs.setString("role", data["role"] ?? "user");

      // optional, boleh disimpan juga kalau API login ngasih nama
      // await prefs.setString("nama", data["nama"] ?? "");

      return data;
    } else {
      throw Exception(data["message"] ?? "Login gagal");
    }
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

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token tidak ditemukan");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/profile"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? {};
    } else {
      throw Exception(data["message"] ?? "Gagal mengambil profile");
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

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("nama");
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(String imagePath) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token tidak ditemukan");
    }

    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception("File gambar tidak ditemukan");
    }

    final mimeType = lookupMimeType(imagePath) ?? "image/jpeg";
    final mimeSplit = mimeType.split("/");

    final url = Uri.parse("${ApiConfig.baseUrl}/profile/photo");

    final request = http.MultipartRequest("PUT", url);

    request.headers.addAll({
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        "foto_profile",
        imagePath,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("========== UPLOAD DEBUG ==========");
    print("UPLOAD URL: $url");
    print("UPLOAD STATUS: ${response.statusCode}");
    print("MIME TYPE: $mimeType");
    print("IMAGE PATH: $imagePath");
    print("FILE SIZE: ${await file.length()}");
    print("UPLOAD BODY: ${response.body}");
    print("==================================");

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data["message"] ?? "Gagal upload foto profile");
      }
    } catch (_) {
      throw Exception(
        "Response bukan JSON. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }
}