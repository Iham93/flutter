import 'dart:convert';
import 'dart:io'; // Penting untuk menangani file gambar
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Alamat IP Backend (Sesuaikan dengan hasil ipconfig laptop Anda)
  // Pastikan HP dan Laptop berada dalam satu jaringan Wi-Fi yang sama
  static const String baseUrl = "http://192.168.1.6:5000/api";

  // Fungsi helper untuk mengambil token dari penyimpanan lokal
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // =====================================================
  // 1. FUNGSI LOGIN (Autentikasi User)
  // =====================================================
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim(), "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Simpan token akses dan nama user untuk keperluan sesi aplikasi
        await prefs.setString("token", data["access_token"]);
        await prefs.setString("full_name", data["user"]["full_name"]);
        return true;
      }
      return false;
    } catch (e) {
      print("Error koneksi login: $e");
      return false;
    }
  }

  // =====================================================
  // 2. FUNGSI SIMPAN SURVEY (Mendukung Multi-Upload Gambar)
  // =====================================================
  // Parameter ke-2 diubah menjadi List<File?> untuk mendukung 3 sesi makan
  Future<bool> saveSurvey(
    Map<String, dynamic> payload,
    List<File?> images,
  ) async {
    try {
      final token = await _getToken();

      // Inisialisasi MultipartRequest
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/surveys/scan"),
      );

      // Tambahkan Header Autentikasi
      request.headers.addAll({"Authorization": "Bearer $token"});

      // Masukkan semua field teks dari payload (nama, nik, gizi, dll)
      payload.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Loop untuk memasukkan banyak file gambar sekaligus (Pagi, Siang, Sore)
      // Key 'image' harus sesuai dengan request.files.getlist('image') di Flask
      for (var image in images) {
        if (image != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', image.path),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201 && response.statusCode != 200) {
        print("Detail Gagal Simpan (${response.statusCode}): ${response.body}");
      }

      // Backend Flask Anda mengembalikan 201 untuk sukses simpan
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error koneksi saveSurvey: $e");
      return false;
    }
  }

  // =====================================================
  // 3. FUNGSI UPDATE SURVEY (Fitur Edit Data Riwayat)
  // =====================================================
  Future<bool> updateSurvey(int id, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();

      // Menggunakan method PUT untuk memperbarui data yang sudah ada
      final response = await http.put(
        Uri.parse("$baseUrl/surveys/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      // Mengembalikan true jika server merespon dengan kode sukses (200 OK)
      return response.statusCode == 200;
    } catch (e) {
      print("Error updateSurvey: $e");
      return false;
    }
  }
}
