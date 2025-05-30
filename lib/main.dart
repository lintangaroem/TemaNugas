import 'package:flutter/material.dart';
import 'package:teman_nugas/screens/homepage/pages/homepage.dart'; // Import halaman homepage
// import 'constant.dart'; // Jika AppTheme Anda ada di constant.dart atau file terpisah
import 'package:teman_nugas/constants/theme.dart'; // Jika AppTheme ada di file app_theme.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teman Nugas App',
      theme: AppTheme.lightTheme, // Menggunakan tema yang sudah Anda buat
      home: const HomePage(), // Atur HomePage sebagai halaman awal
      debugShowCheckedModeBanner: false,
    );
  }
}