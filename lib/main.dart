import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_pages.dart'; //
import 'auth_pages.dart'; //
import 'screens/food_detect_screen.dart'; //
import 'screens/chat_screen.dart'; // Pastikan Anda sudah membuat file ini

void main() {
  runApp(const GiziLensApp());
}

class GiziLensApp extends StatelessWidget {
  const GiziLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GiziLens Posyandu',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        fontFamily: 'Poppins', // Menyesuaikan desain modern di video Anda
      ),
      home: const SplashWrapper(), //
      // PENDAFTARAN RUTE LENGKAP
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/food_detect': (context) => const FoodDetectScreen(),
        '/chat': (context) => const ChatScreen(), // AKTIFKAN CHAT AI
        // '/history': (context) => const HistoryScreen(), // Aktifkan jika file sudah ada
      },
    );
  }
}

class SplashWrapper extends StatelessWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final prefs = snapshot.data as SharedPreferences;
        final token = prefs.getString("token"); // Cek status login

        // Alur Flow 1: Jika ada token langsung ke Home, jika tidak ke Login
        return token != null ? const HomePage() : const LoginPage();
      },
    );
  }
}
