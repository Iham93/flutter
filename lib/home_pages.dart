import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/food_detect_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/edit_survey_screen.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fullName = "Kader";
  String nikKader = "-";
  String wilayahKader = "Belum Diatur";
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _recentSurveys = [];
  int _totalSurveys = 0;
  int _normalCount = 0;
  int _criticalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // MEMUAT DATA DASHBOARD DAN PROFIL USER
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      // 1. Ambil data Profil (ID & Wilayah)
      final profileRes = await http.get(
        Uri.parse("${ApiService.baseUrl}/auth/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (profileRes.statusCode == 200) {
        final userData = jsonDecode(profileRes.body);
        setState(() {
          fullName = userData['full_name'] ?? "Kader";
          nikKader = userData['nik'] ?? "-";
          wilayahKader = userData['wilayah'] ?? "Belum Diatur";
        });
      }

      // 2. Ambil data Survey
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/surveys"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        List<dynamic> data = resData["data"] ?? [];

        int normal = 0;
        int critical = 0;
        for (var s in data) {
          if (s['status_gizi'].toString().toLowerCase().contains('normal')) {
            normal++;
          } else {
            critical++;
          }
        }

        setState(() {
          _recentSurveys = data;
          _totalSurveys = data.length;
          _normalCount = normal;
          _criticalCount = critical;
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  // DIALOG PANDUAN PENGGUNAAN
  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cara Penggunaan"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("1. Klik 'Mulai Scan' untuk memotret menu makanan balita."),
              SizedBox(height: 8),
              Text(
                "2. Gunakan 'Tanya AI' untuk mendapatkan saran nutrisi otomatis.",
              ),
              SizedBox(height: 8),
              Text(
                "3. Cek hasil gizi; jika muncul status 'Kritis', ikuti saran AI.",
              ),
              SizedBox(height: 8),
              Text(
                "4. Jika ada kesalahan input, klik data di Riwayat untuk mengedit.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Mengerti"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      const ChatScreen(),
      _buildHistoryList(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0 || index == 2) _loadDashboardData();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal[800],
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_rounded),
            label: "Riwayat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: "Profil",
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }

  // --- TAB 1: BERANDA ---
  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildModernHeader(),
              const SizedBox(height: 25),
              _buildMainActionCard(),
              const SizedBox(height: 25),
              _buildGiziStatsBar(),
              const SizedBox(height: 30),
              _buildRecentSectionTitle(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildRecentHistoryList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Bertugas,",
                style: TextStyle(color: Colors.teal[100], fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildGiziStatsBar() {
    double total = _totalSurveys > 0 ? _totalSurveys.toDouble() : 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sebaran Status Gizi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (_normalCount / total * 100).toInt().clamp(1, 100),
                      child: Container(color: Colors.teal),
                    ),
                    Expanded(
                      flex: (_criticalCount / total * 100).toInt().clamp(
                        1,
                        100,
                      ),
                      child: Container(color: Colors.orange[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _indicatorItem("Normal", _normalCount, Colors.teal),
                _indicatorItem("Kritis", _criticalCount, Colors.orange[800]!),
                _indicatorItem("Total", _totalSurveys, Colors.blueGrey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: $count",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMainActionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, "/food_detect"),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[700]!, Colors.orange[900]!],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Scan Gizi Balita",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Deteksi via Kamera AI",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Riwayat Terbaru",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedIndex = 2),
            child: const Text("Semua"),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistoryList() {
    if (_recentSurveys.isEmpty) return const Text("Belum ada data.");
    return Column(
      children: _recentSurveys
          .take(4)
          .map((s) => _buildHistoryCard(s))
          .toList(),
    );
  }

  // --- TAB 3: RIWAYAT ---
  Widget _buildHistoryList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pemeriksaan"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _recentSurveys.length,
              itemBuilder: (context, index) =>
                  _buildHistoryCard(_recentSurveys[index]),
            ),
    );
  }

  Widget _buildHistoryCard(dynamic survey) {
    bool isCrit = !survey["status_gizi"].toString().toLowerCase().contains(
      "normal",
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCrit ? Colors.red[50] : Colors.teal[50],
          child: Icon(
            Icons.child_care_rounded,
            color: isCrit ? Colors.red : Colors.teal,
          ),
        ),
        title: Text(
          survey["nama_balita"] ?? "Tanpa Nama",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${survey['status_gizi']}"),
        trailing: const Icon(Icons.edit_note_rounded),
        onTap: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditSurveyScreen(survey: survey),
            ),
          );
          if (refresh == true) _loadDashboardData();
        },
      ),
    );
  }

  // --- TAB 4: PROFIL LENGKAP ---
  Widget _buildProfilePage() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 30),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildProfileMenu(Icons.badge_rounded, "ID / NIK Kader", nikKader),
          _buildProfileMenu(
            Icons.location_on_rounded,
            "Wilayah Tugas",
            wilayahKader,
          ),
          _buildProfileMenu(
            Icons.help_center_rounded,
            "Panduan Aplikasi",
            "Klik untuk melihat",
            onTap: _showTutorial,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text("LOGOUT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(
    IconData icon,
    String title,
    String value, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.teal[800]),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(value),
      onTap: onTap,
    );
  }
}
