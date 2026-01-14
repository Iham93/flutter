import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodApi {
  // IP Laptop Anda (Gunakan hasil ipconfig terakhir)
  static const String baseUrl = "http://192.168.1.6:5000/api";

  static Future<Map<String, dynamic>> detectFood(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/detect-food"),
      );

      // Menambahkan file gambar ke request
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      // Mengirim request dan mengonversi stream ke response biasa
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"error": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Gagal terhubung ke server: $e"};
    }
  }
}
