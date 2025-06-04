import 'package:flutter/material.dart';

// --- WARNA APLIKASI ---
class AppColors {
  static const Color primaryBlue = Color(0xFF448BD2); // Biru utama dari UI Anda
  static const Color darkBlue = Color(0xFF195E92);   // Biru lebih gelap
  static const Color redAlert = Color(0xFFEB5757);   // Merah untuk error
  static const Color background = Color(0xFFFFFFFF); // Latar belakang utama
  static const Color lightGrey = Color(0xFFF0F0F0);  // Abu-abu muda untuk card, divider
  static const Color textDark = Color(0xFF212121);   // Teks gelap utama
  static const Color textLight = Color(0xFF757575);  // Teks lebih terang/abu-abu
  static const Color greenSuccess = Color(0xFF27AE60); // Hijau untuk sukses
  static const Color orangeWarning = Color(0xFFF2994A); // Oranye untuk peringatan
  static const Color disabledButton = Color(0xFFBDBDBD); // Warna tombol non-aktif
}
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'PlusJakartaSans', // Ganti dengan font Anda jika perlu
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 18,
    fontWeight: FontWeight.w600, // Semi-bold
    color: AppColors.textDark,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.4, // Jarak antar baris
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.4,
  );

   static const TextStyle labelSmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.background, // Teks tombol biasanya putih
    letterSpacing: 0.5,
  );
}
