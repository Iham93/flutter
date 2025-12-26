import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'home_pages.dart'; // Di sini ada kelas MainScreen

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _hpController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLogin();
  }

  void _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      // FIX 1: Navigasi ke MainScreen (BottomNav Wrapper)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  // --- LOGIC LOGIN & REGISTER ---
  void _handleLogin() async {
    setState(() => _isLoading = true);
    bool success = await _apiService.login(
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (success) {
      // FIX 2: Navigasi ke MainScreen (BottomNav Wrapper)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      _snack("Login Gagal. Cek Email/Password.", Colors.red);
    }
  }

  void _handleRegister() async {
    setState(() => _isLoading = true);
    bool success = await _apiService.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _nikController.text,
      _hpController.text,
    );
    setState(() => _isLoading = false);

    if (success) {
      _snack("Berhasil Daftar! Silakan Login.", Colors.green);
      _tabController.animateTo(0);
    } else {
      _snack("Gagal Daftar. Cek koneksi/data.", Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. HEADER BACKGROUND (HIJAU KONSISTEN)
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                // Menggunakan Hijau yang sama dengan Home Page (0xFF2E7D32)
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
          ),

          // 2. FLOATING FORM CARD
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // LOGO TANPA BUNDARAN
                Center(
                  child: Column(
                    children: [
                      // Logo Tanpa Wrapper Bundaran Putih
                      Image.asset(
                        'assets/logo.png',
                        height: 90, // Ukuran logo diperbesar sedikit
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.health_and_safety,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "GiziLens",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Pantau Gizi, Hidup Sehat",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // FLOATING FORM CARD
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Tab Bar Custom
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF2E7D32),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFFFF9100),
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: "Masuk"),
                              Tab(text: "Daftar"),
                            ],
                          ),
                        ),

                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // === FORM LOGIN ===
                              ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  _modernInput(
                                    "Email",
                                    Icons.email_outlined,
                                    _emailController,
                                  ),
                                  const SizedBox(height: 16),
                                  _modernInput(
                                    "Password",
                                    Icons.lock_outline,
                                    _passwordController,
                                    obscure: true,
                                  ),
                                  const SizedBox(height: 30),
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : ElevatedButton(
                                          onPressed: _handleLogin,
                                          child: const Text("MASUK"),
                                        ),
                                ],
                              ),

                              // === FORM REGISTER ===
                              ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  _modernInput(
                                    "Nama Lengkap",
                                    Icons.person_outline,
                                    _nameController,
                                  ),
                                  const SizedBox(height: 16),
                                  _modernInput(
                                    "NIK",
                                    Icons.credit_card,
                                    _nikController,
                                    type: TextInputType.number,
                                  ),
                                  const SizedBox(height: 16),
                                  _modernInput(
                                    "No HP",
                                    Icons.phone,
                                    _hpController,
                                    type: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  _modernInput(
                                    "Email",
                                    Icons.email_outlined,
                                    _emailController,
                                  ),
                                  const SizedBox(height: 16),
                                  _modernInput(
                                    "Password",
                                    Icons.lock_outline,
                                    _passwordController,
                                    obscure: true,
                                  ),
                                  const SizedBox(height: 30),
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : ElevatedButton(
                                          onPressed: _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFFF9100,
                                            ),
                                          ),
                                          child: const Text("DAFTAR AKUN"),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernInput(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
