import 'package:flutter/material.dart';
import 'constant.dart'; // Pastikan path ini benar

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Mengaktifkan Material 3 jika diinginkan
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'PlusJakartaSans', // Pastikan font ini ada di pubspec.yaml dan assets
      
      appBarTheme: AppBarTheme(
        elevation: 0.5, // Sedikit shadow
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background, // Untuk Material 3
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
        titleTextStyle: AppTextStyles.heading.copyWith(fontSize: 20), // Sesuaikan ukuran untuk AppBar
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.background,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Border radius lebih besar
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24), // Padding lebih nyaman
          elevation: 2,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        )
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGrey.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // Tidak ada border default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
        errorStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.redAlert),
      ),

      cardTheme: CardTheme(
        elevation: 1.5, // Shadow lebih halus
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Default margin untuk card
        color: AppColors.background,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primaryBlue,
        titleTextStyle: AppTextStyles.titleMedium,
        subtitleTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return Colors.grey[300];
        }),
        checkColor: WidgetStateProperty.all(AppColors.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: Colors.grey[400]!, width: 1.5),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textLight.withOpacity(0.7),
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 5.0,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.background,
        elevation: 4,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.heading.copyWith(fontSize: 18),
        contentTextStyle: AppTextStyles.bodyLarge,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppColors.textDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.background),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColors.lightGrey.withOpacity(0.8),
        thickness: 1,
      )
    );
  }
}
