import 'package:flutter/material.dart';
import 'screens/home_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SikasApp());
}

class SikasApp extends StatelessWidget {
  const SikasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIKAS - Kas & Stok Kerupuk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD97706), // Warna Amber / Keemasan Khas Kerupuk Matang
          primary: const Color(0xFFD97706),
          secondary: const Color(0xFF15803D), // Warna Hijau Pemasukan / Kas
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.8),
          ),
        ),
      ),
      home: const HomeDashboardScreen(),
    );
  }
}
