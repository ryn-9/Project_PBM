import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/api_config.dart';

class AuthService {
  static Future<String?> getFcmToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();

      print("FCM TOKEN GENERATED: $token");

      return token;
    } catch (e) {
      print("Gagal mengambil FCM token: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final fcmToken = await getFcmToken();

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "fcm_token": fcmToken,
      }),
    );

    print("========== LOGIN DEBUG ==========");
    print("LOGIN URL: ${ApiConfig.baseUrl}/auth/login");
    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");
    print("FCM TOKEN SENT: $fcmToken");
    print("=================================");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", data["token"]?.toString() ?? "");
      await prefs.setString("role", data["role"]?.toString() ?? "user");

      if (data["user"] != null) {
        await prefs.setString("nama", data["user"]["nama"]?.toString() ?? "");
        await prefs.setString("email", data["user"]["email"]?.toString() ?? "");
      } else {
        await prefs.setString("nama", data["nama"]?.toString() ?? "");
        await prefs.setString("email", data["email"]?.toString() ?? "");
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await prefs.setString("fcm_token", fcmToken);
      }

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
    final fcmToken = await getFcmToken();

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
        "fcm_token": fcmToken,
      }),
    );

    print("========== REGISTER DEBUG ==========");
    print("REGISTER URL: ${ApiConfig.baseUrl}/auth/register");
    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER BODY: ${response.body}");
    print("FCM TOKEN SENT: $fcmToken");
    print("====================================");

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

  static Future<String?> getSavedFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("fcm_token");
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