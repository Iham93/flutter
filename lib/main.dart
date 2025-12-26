import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GiziLens Modern',
      theme: ThemeData(
        useMaterial3: true,
        // Font Modern
        textTheme: GoogleFonts.poppinsTextTheme(),

        // Warna Utama: Hijau Tosca Modern & Aksen Oranye
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5), // Hijau Tosca
          secondary: const Color(0xFFFF9100), // Oranye
          surface: const Color(0xFFF0F4F8), // Background Abu Kebiruan (Soft)
        ),

        // Style Input Field (Isian Teks)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),

        // Style Tombol
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            backgroundColor: const Color(0xFF00BFA5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}
