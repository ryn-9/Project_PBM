import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageKitService {
  static Future<String?> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://upload.imagekit.io/api/v1/files/upload'),
      );

      String auth = base64Encode(
        utf8.encode('private_WBV4snGScwQpjTBkbDtmfgWbR7I=:'),
      );

      request.headers['Authorization'] = 'Basic $auth';

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      request.fields['fileName'] =
          'laporan_${DateTime.now().millisecondsSinceEpoch}.jpg';

      var response = await request.send();
      var res = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var json = jsonDecode(res);
        return json['url'];
      } else {
        print("Upload gagal: $res");
        return null;
      }
    } catch (e) {
      print("ERROR upload: $e");
      return null;
    }
  }
}