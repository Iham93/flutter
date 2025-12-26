import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// Tambahkan import baru yang dibutuhkan untuk Base64 dan SharedPreferences
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Tambahkan import geolocator
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';
import 'auth_pages.dart';

// =========================================================
// WARNA TEMA (Konsisten dari main.dart)
// =========================================================
final Color _greenPrimary = const Color(0xFF2E7D32);
final Color _orangeAccent = const Color(0xFFFF9100);
final Color _bgSoft = const Color(0xFFF0F4F8);

// =========================================================
// 0. MAIN SCREEN (BOTTOM NAVIGATION BAR) - FIX SINKRONISASI
// =========================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Hapus definisi _pages di sini. Akan didefinisikan di build() dengan Key unik.

  @override
  void initState() {
    super.initState();
    // Tidak perlu inisialisasi _pages di sini lagi
  }

  void _handleLogout() async {
    final apiService = ApiService();
    await apiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      // FIX: Gunakan List yang didefinisikan di sini dengan Key unik
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardPage(),
          const AIChatPage(),
          // FIX SINKRONISASI: Key berubah setiap kali _selectedIndex adalah 2 (Riwayat),
          // yang memaksa _AnalysisHistoryPageState.initState() dijalankan lagi.
          AnalysisHistoryPage(key: ValueKey('history_tab_$_selectedIndex')),
          ProfilePage(onLogout: _handleLogout),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _greenPrimary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Utama",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: "Chat AI",
            key: ValueKey('ChatTab'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "Riwayat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 1. DASHBOARD PAGE (FINAL REVISION & SMOOTH SCROLL)
// =========================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  String _userName = "User";
  List<dynamic> _surveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    String name = await _apiService.getUserName();
    var surveys = await _apiService.getSurveys();

    if (mounted) {
      setState(() {
        _userName = name;
        _surveys = surveys;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _greenPrimary,
        // FIX SCROLLING: Menggunakan BouncingScrollPhysics untuk smooth scroll
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // A. HEADER CUSTOM APP BAR (Bagian Atas)
            SliverAppBar(
              backgroundColor: _greenPrimary,
              automaticallyImplyLeading: false,
              expandedHeight:
                  180, // Tinggi dikurangi agar konten bawah cepat terlihat
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _goToNotifications, // Navigasi Notifikasi FIX
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: Text(
                  // Menampilkan Email atau Nama Pengguna (FIXED)
                  "Selamat Datang, $_userName!",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_greenPrimary, const Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // B. KARTU AKSI & STATISTIK (Sliver List Statis)
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KARTU AKSI UTAMA (SCAN) - FIX PENEMPATAN
                      _buildScanActionCard(context),
                      const SizedBox(height: 25),

                      // STATISTIK
                      _buildStatCardRow(),
                      const SizedBox(height: 25),

                      // JUDUL LIST
                      Text(
                        "Riwayat Pemeriksaan Terbaru",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ]),
            ),

            // C. LIST DATA SURVEYS (Sliver List Builder - PERFORMANCE FIX)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _isLoading
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(color: _greenPrimary),
                      ),
                    )
                  : _surveys.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList.builder(
                      itemCount: _surveys.length,
                      itemBuilder: (context, index) {
                        return _buildSurveyItem(_surveys[index]);
                      },
                    ),
            ),

            // D. PADDING BAWAH
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildScanActionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _orangeAccent.withOpacity(0.15), // Bayangan Oranye Halus
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Scan Gizi Makanan",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _greenPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mulai analisis gizi balita sekarang.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanPage()),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text("Mulai Scan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Icon Placeholder
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 50,
            color: _orangeAccent.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardRow() {
    return Row(
      children: [
        _buildStatCard(
          "Total Data",
          "${_surveys.length}",
          Icons.folder_shared,
          Colors.blue,
        ),
        const SizedBox(width: 15),
        _buildStatCard(
          "Status Gizi",
          "Normal",
          Icons.health_and_safety,
          _orangeAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // FIX SURVEY ITEM LIST
  Widget _buildSurveyItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.child_care, color: _greenPrimary),
        title: Text(
          // Menampilkan NIK
          item['nik'] ?? "Tanpa NIK",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          // FIX: Menggunakan Wilayah dan Kalori yang tersedia di model
          "Wilayah: ${item['wilayah']} | Kalori: ${item['kalori']}",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {},
      ),
    );
  }
  // END FIX SURVEY ITEM LIST

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "Belum ada data survei",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 2. AI CHAT PAGE (CHAT ASSISTANT)
// =========================================================
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    // Scroll ke bawah secara otomatis (smooth scroll)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    _controller.clear();
    _addMessage(message, true); // Tambahkan pesan pengguna ke UI

    setState(() => _isSending = true);

    // Tampilkan placeholder bot
    _addMessage("Mengetik...", false);

    final aiResponse = await _apiService.sendChatMessage(message);

    // Hapus placeholder dan ganti dengan balasan AI
    setState(() {
      _messages.removeLast();
      _addMessage(aiResponse, false);
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: Text(
          "Chat interaktif AI GiziLens",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(), // Smooth scroll pada chat
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatMessage(_messages[index]);
              },
            ),
          ),

          // Input Chat Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: _isSending
                          ? "AI sedang memproses..."
                          : "Tulis pertanyaan anda...",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isSending ? Colors.grey : _greenPrimary,
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final bubbleColor = message.isUser ? _orangeAccent : Colors.grey[300];
    final textColor = message.isUser ? Colors.white : Colors.black87;
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            topRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
            topLeft: message.isUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.poppins(color: textColor, fontSize: 14),
        ),
      ),
    );
  }
}

// =========================================================
// 3. ANALYSIS HISTORY PAGE (Riwayat Analisis - DYNAMIC)
// =========================================================
class AnalysisHistoryPage extends StatefulWidget {
  const AnalysisHistoryPage({super.key});

  @override
  State<AnalysisHistoryPage> createState() => _AnalysisHistoryPageState();
}

class _AnalysisHistoryPageState extends State<AnalysisHistoryPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _surveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Panggil _loadHistory setiap kali widget diinisialisasi
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Memanggil endpoint Flask /api/surveys
    var surveys = await _apiService.getSurveys();
    if (mounted) {
      setState(() {
        _surveys = surveys;
        _isLoading = false;
      });
    }
  }

  // Menggunakan widget list item yang sama seperti Dashboard
  Widget _buildSurveyItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.child_care, color: _greenPrimary),
        title: Text(
          item['nik'] ?? "Tanpa NIK",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          // FIX: Menggunakan Tanggal dan Kalori untuk riwayat
          "Tanggal: ${item['date']} | Kalori: ${item['kalori']}",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Riwayat Analisis",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _surveys.isEmpty
          ? Center(
              child: Text(
                "Halaman Riwayat Analisis Gizi Kosong",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _surveys.length,
              itemBuilder: (context, index) {
                return _buildSurveyItem(_surveys[index]);
              },
            ),
    );
  }
}

// =========================================================
// 4. PROFILE PAGE (Pengaturan Akun)
// =========================================================
class ProfilePage extends StatelessWidget {
  final Function onLogout;
  const ProfilePage({required this.onLogout, super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return FutureBuilder<String>(
      future: apiService.getUserName(),
      builder: (context, snapshot) {
        final currentUserName = snapshot.data ?? "Memuat...";

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Pengaturan Akun",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: Icon(
                  Icons.account_circle,
                  size: 40,
                  color: _greenPrimary,
                ),
                title: Text(
                  currentUserName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Akun Terdaftar",
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
              const Divider(),
              _buildSettingTile("Ubah Profil", Icons.edit, () {}),
              _buildSettingTile("Ganti Kata Sandi", Icons.lock, () {}),
              _buildSettingTile(
                "Notifikasi Push",
                Icons.notifications_active,
                () {},
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => onLogout(),
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  label: Text(
                    "KELUAR",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}

// =========================================================
// 5. NOTIFICATION PAGE (FIXED)
// =========================================================
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: Text(
          "Pengingat Gizi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Tidak ada notifikasi",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Jadwal makan dan imunisasi akan muncul di sini.",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 6. SCAN PAGE (YOLO-Ready Camera Structure)
// =========================================================
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  Future<void> _takePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    // Gunakan ImageSource.gallery untuk testing jika kamera HP bermasalah
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    final apiService = ApiService();

    if (image != null && context.mounted) {
      // 1. Baca file dan konversi ke Base64
      File imageFile = File(image.path);
      String base64Image = base64Encode(imageFile.readAsBytesSync());

      // 2. Navigasi ke AnalysisPage dan biarkan AnalysisPage yang menampilkan loading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisPage(
            imagePath: image.path,
            imageBase64: base64Image, // Kirim Base64 untuk analisis
            apiService: apiService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Pindai Makanan (YOLO Prep)",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder Kamera View
          Positioned.fill(
            child: Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Text(
                  "YOLO Live Camera Feed Placeholder",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ),

          // Area Scan (Bounding Box Visualizer)
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.limeAccent, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "Area Deteksi YOLO",
                style: GoogleFonts.poppins(
                  color: Colors.limeAccent,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Tombol Capture di bawah
          Positioned(
            bottom: 50,
            child: FloatingActionButton(
              onPressed: () => _takePicture(context),
              backgroundColor: _orangeAccent,
              heroTag: 'cameraFAB',
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            ),
          ),

          Positioned(
            bottom: 120,
            child: Text(
              "Pastikan objek berada dalam kotak deteksi",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 7. ANALYSIS PAGE (Hasil Analisis Gizi - DYNAMIC)
// =========================================================
class AnalysisPage extends StatefulWidget {
  final String imagePath;
  final String imageBase64;
  final ApiService apiService;
  const AnalysisPage({
    required this.imagePath,
    required this.imageBase64,
    required this.apiService,
    super.key,
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  Map<String, dynamic>? _analysisResult;
  bool _isLoading = true;
  // Tambahkan state baru untuk lokasi
  String _currentLocation = 'Memuat lokasi...';

  @override
  void initState() {
    super.initState();
    _analyzeFood();
    // Panggil fungsi lokasi saat halaman dimuat
    _getCurrentLocation();
  }

  void _analyzeFood() async {
    final result = await widget.apiService.analyzeFoodImage(widget.imageBase64);

    if (mounted) {
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    }
  }

  // FUNGSI UNTUK LOKASI (Membutuhkan package geolocator)
  Future<void> _getCurrentLocation() async {
    try {
      // Permintaan izin lokasi
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _currentLocation = "Akses lokasi ditolak.");
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation =
              "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = "Gagal mendapatkan lokasi.";
        });
      }
    }
  }

  void _editManual(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditManualPage()),
    );
  }

  // Ganti fungsi _confirmAndSave
  void _confirmAndSave(BuildContext context) async {
    if (_analysisResult == null || _analysisResult!['error'] != null) return;

    // 1. Ambil data yang dibutuhkan dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final dataToSave = {
      // Data statis dari user login
      'nik': prefs.getString('nik') ?? '00000000',
      'wilayah': prefs.getString('wilayah') ?? 'Unknown',
      'kader': prefs.getString('user_name') ?? 'User',

      // Data dinamis dari API
      'kalori_int': _analysisResult!['kalori_total'],
      'image_path': widget.imagePath,

      // Data Lokasi Real-time
      'lokasi': _currentLocation, // Mengirim lokasi GPS HP
    };

    // 2. Kirim ke API Save
    bool success = await widget.apiService.saveNewSurvey(dataToSave);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data berhasil disimpan!"),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke Dashboard utama
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menyimpan data ke server."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNutrientBar(String name, int value, int target, Color color) {
    double progress = value / target;
    // Pastikan progress tidak melebihi 1.0 (100%)
    if (progress > 1.0) progress = 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                "${value}g / ${target}g",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(String ingredient, String detail) {
    return ListTile(
      leading: const Icon(Icons.circle, size: 8, color: Colors.grey),
      title: Text(
        ingredient,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      trailing: Text(
        detail,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Menganalisis...",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 20),
              Text(
                "Menganalisis gambar dengan YOLO...",
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 20),
              Text(
                "Lokasi HP: $_currentLocation",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Jika gagal atau null
    if (_analysisResult == null || _analysisResult!['error'] != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Error Analisis",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _analysisResult?['error'] ?? "Gagal terhubung ke analisis.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    // Data Dinamis dari API
    final results = _analysisResult!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hasil Analysis Gizi",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Image Preview (Hasil Foto)
          Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(
                    File(widget.imagePath),
                  ), // Menampilkan gambar yang diambil
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Total Kalori Section
          Text(
            "Estimasi Total Kalori:",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
          Text(
            "${results['kalori_total']} Kkal", // DATA DINAMIS
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Detail Nutrisi (Simplified)
          _buildNutrientBar(
            "Protein",
            results['protein'] ?? 0,
            100,
            Colors.redAccent,
          ),
          _buildNutrientBar(
            "Karbohidrat",
            results['karbohidrat'] ?? 0,
            250,
            Colors.green,
          ),
          _buildNutrientBar("Lemak", results['lemak'] ?? 0, 70, Colors.orange),

          const SizedBox(height: 30),
          Text(
            "Ingredient Breakdown (Perkiraan)",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const Divider(),

          // List Bahan Makanan Dinamis
          ...(results['bahan_list'] as List? ?? [])
              .map(
                (item) => _buildIngredientItem(
                  item['nama'] ?? 'Unknown',
                  item['detail'] ?? 'N/A',
                ),
              )
              ,

          const SizedBox(height: 40),

          // Informasi Lokasi HP (Tambahan UX)
          Text(
            "Lokasi Pengambilan Data:",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _currentLocation,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editManual(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Edit Manual",
                    style: GoogleFonts.poppins(color: Colors.grey.shade700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _confirmAndSave(context), // PANGGIL FUNGSI SAVE
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Konfirmasi & Simpan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// =========================================================
// 8. EDIT MANUAL PAGE (Edit Asupan)
// =========================================================
class EditManualPage extends StatelessWidget {
  const EditManualPage({super.key});

  Widget _buildManualField(String label, {String initialValue = ""}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Manual Asupan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            "Edit Komposisi Makanan",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          _buildManualField("Nama Makanan", initialValue: "Nasi Ayam Panggang"),
          _buildManualField("Total Kalori (Kkal)", initialValue: "420"),
          _buildManualField("Protein (g)", initialValue: "70"),
          _buildManualField("Karbohidrat (g)", initialValue: "80"),
          _buildManualField("Lemak (g)", initialValue: "15"),

          const SizedBox(height: 30),
          // Tombol Simpan
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: Text(
              "Simpan Perubahan",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
