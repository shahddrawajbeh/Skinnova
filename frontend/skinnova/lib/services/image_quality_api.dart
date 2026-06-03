import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageQualityApi {
  static const String baseUrl = "http://192.168.1.15:8000";

  static Future<Map<String, dynamic>> checkImage(File image) async {
    final uri = Uri.parse("$baseUrl/check-image");

    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath("image", image.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body);
  }
}
