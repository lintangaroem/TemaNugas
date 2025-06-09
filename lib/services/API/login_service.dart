import 'package:flutter/material.dart';
import '/providers/auth_provider.dart';

// Class untuk menangani login secara terpisah dari UI
class LoginService {
  final AuthProvider authProvider;
  
  LoginService(this.authProvider);
  
  // Method untuk login yang tidak bergantung pada context
  Future<LoginResult> login(String email, String password, {BuildContext? context}) async {
    try {
      print("LoginService: Starting login process");
      
      // Reset error dan set status
      authProvider.clearError();
      
      // Panggil login di AuthProvider
      final success = await authProvider.login(email, password);
      
      print("LoginService: Login result: $success");
      
      if (success) {
        // Jika context tersedia, navigasi ke home
        if (context != null) {
          // Tambahkan delay kecil untuk memastikan state sudah diupdate
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false, // Remove all previous routes
            );
          }
        }
        
        return LoginResult(
          success: true,
          message: "Login berhasil",
        );
      } else {
        return LoginResult(
          success: false,
          message: authProvider.errorMessage ?? "Login gagal",
        );
      }
    } catch (e) {
      print("LoginService: Exception during login: $e");
      return LoginResult(
        success: false,
        message: "Terjadi kesalahan: ${e.toString().replaceFirst("Exception: ", "")}",
      );
    }
  }
}

// Class untuk hasil login
class LoginResult {
  final bool success;
  final String message;
  
  LoginResult({required this.success, required this.message});
}
