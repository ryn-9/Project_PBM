import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "ISI_CLOUD_NAME_KAMU";
  static const String uploadPreset = "ISI_UPLOAD_PRESET_KAMU";

  static Future<String> uploadImage(File imageFile) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields["upload_preset"] = uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(responseBody);
      return data["secure_url"];
    } else {
      throw Exception("Upload Cloudinary gagal: $responseBody");
    }
  }
}