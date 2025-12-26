import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // =======================================================================
  // PENTING: Pastikan IP ini sesuai dengan IP Laptop/Komputer Anda saat ini
  // UPDATE SESUAI IPCONFIG TERBARU: 192.168.1.9
  // =======================================================================
  static const String baseUrl = 'http://192.168.1.9:5000/api';

  // --- HELPER: GET HEADERS ---
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. LOGIN
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Menyimpan data utama
        await prefs.setString('user_name', data['full_name'] ?? 'User');
        await prefs.setString('token', data['access_token']);

        // Menyimpan NIK dan Wilayah dari respons Flask
        await prefs.setString('nik', data['nik'] ?? '00000000');
        await prefs.setString('wilayah', data['wilayah'] ?? 'Unknown');
        
        // PENTING: Menyimpan ID user untuk keperluan filter data pribadi
        await prefs.setString('user_id', data['user_id'].toString());

        return true;
      }
      return false;
    } catch (e) {
      print("Error Login: $e");
      return false;
    }
  }

  // 2. REGISTER
  Future<bool> register(
    String nama,
    String email,
    String password,
    String nik,
    String hp,
  ) async {
    final url = Uri.parse('$baseUrl/users');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': nama,
          'email': email,
          'password': password,
          'nik': nik,
          'phone_number': hp,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error Register: $e");
      return false;
    }
  }

  // 3. GET DATA SURVEI (PERSONAL DATA)
  Future<List<dynamic>> getSurveys() async {
    final url = Uri.parse('$baseUrl/surveys/personal');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error Get Data: $e");
      return [];
    }
  }

  // 4. AMBIL NAMA USER
  Future<String> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? "Pengguna";
  }

  // 5. LOGOUT
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // 6. FUNGSI CHAT AI (Groq)
  Future<String> sendChatMessage(String message) async {
    final url = Uri.parse('$baseUrl/chat');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Maaf, terjadi kesalahan di server.';
      } else {
        return 'Gagal terhubung ke AI. (Status: ${response.statusCode})';
      }
    } catch (e) {
      return 'Error koneksi: Server Flask tidak merespons.';
    }
  }

  // 7. ANALISIS GAMBAR (YOLO)
  Future<Map<String, dynamic>> analyzeFoodImage(String imageBase64) async {
    final url = Uri.parse('$baseUrl/surveys/analyze');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({'image': imageBase64}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "error": "Gagal analisis. Status: ${response.statusCode}. Pesan: ${errorBody['error'] ?? 'Tidak diketahui'}",
        };
      }
    } catch (e) {
      return {"error": "Error koneksi saat analisis: $e"};
    }
  }

  // 8. SIMPAN DATA SURVEI BARU
  Future<bool> saveNewSurvey(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/surveys/add');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201; 
    } catch (e) {
      print("Error Save Survey: $e");
      return false;
    }
  }
}