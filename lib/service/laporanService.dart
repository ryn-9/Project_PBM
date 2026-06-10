import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class LaporanService {
  static Future<List<dynamic>> getLaporanPublic() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/laporan/public"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    ).timeout(
      const Duration(seconds: 20),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    }

    throw Exception(data["message"] ?? "Gagal mengambil laporan publik");
  }

  static Future<List<dynamic>> getLaporanByUser(int userId) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/laporan/user/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    ).timeout(
      const Duration(seconds: 20),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    }

    throw Exception(data["message"] ?? "Gagal mengambil laporan user");
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
    ).timeout(
      const Duration(seconds: 20),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["data"] ?? [];
    }

    throw Exception(data["message"] ?? "Gagal mengambil riwayat laporan");
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
    File? mediaFile,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/laporan/$laporanId");

    final request = http.MultipartRequest("PUT", uri);

    request.headers.addAll({
      "Accept": "application/json",
    });

    request.fields["user_id"] = userId.toString();
    request.fields["judul"] = judul;
    request.fields["deskripsi"] = deskripsi;
    request.fields["jenis_laporan"] = jenisLaporan;
    request.fields["alamat"] = alamat;

    if (latitude != null) {
      request.fields["latitude"] = latitude.toString();
    }

    if (longitude != null) {
      request.fields["longitude"] = longitude.toString();
    }

    if (mediaFile != null) {
      final fileName = mediaFile.path
          .split(Platform.pathSeparator)
          .last
          .toLowerCase();

      final MediaType contentType = _getImageContentType(fileName);

      request.files.add(
        await http.MultipartFile.fromPath(
          "media",
          mediaFile.path,
          contentType: contentType,
          filename: _safeImageFileName(fileName),
        ),
      );
    }

    try {
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 45),
          );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("STATUS UPDATE LAPORAN: ${response.statusCode}");
      debugPrint("BODY UPDATE LAPORAN: ${response.body}");

      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception("Response server tidak valid: ${response.body}");
      }

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(data["message"] ?? "Gagal update laporan");
    } on SocketException {
      throw Exception("Tidak ada koneksi internet");
    } on HttpException {
      throw Exception("Gagal terhubung ke server");
    } on FormatException {
      throw Exception("Format response server tidak valid");
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  static MediaType _getImageContentType(String fileName) {
    if (fileName.endsWith(".png")) {
      return MediaType("image", "png");
    }

    if (fileName.endsWith(".webp")) {
      return MediaType("image", "webp");
    }

    if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
      return MediaType("image", "jpeg");
    }

    return MediaType("image", "jpeg");
  }

  static String _safeImageFileName(String fileName) {
    if (fileName.endsWith(".jpg") ||
        fileName.endsWith(".jpeg") ||
        fileName.endsWith(".png") ||
        fileName.endsWith(".webp")) {
      return fileName;
    }

    return "laporan_update.jpg";
  }
}