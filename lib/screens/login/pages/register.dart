import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Sesuaikan path ini jika lokasi file berbeda di proyek Anda
import '../../../providers/auth_provider.dart';
import '../../../constants/constant.dart'; // Menggunakan path dari kode Anda
import '../../../constants/theme.dart';   // Menggunakan path dari kode Anda
// LoginPage tidak perlu diimport jika navigasi setelah register dihandle AuthWrapper
import 'login.dart'; // Untuk kembali ke login jika diperlukan secara manual

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(); // Mengganti usernameController
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isLoading = false;
  // String? errorText; // Tidak digunakan lagi, kita pakai SnackBar

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleRepeatPasswordVisibility() {
    setState(() => _obscureRepeatPassword = !_obscureRepeatPassword);
  }

  // Fungsi isValidEmail tidak perlu di sini jika validasi email sudah cukup di TextFormField
  // bool isValidEmail(String email) {
  //   return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  // }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String passwordConfirmation = _repeatPasswordController.text.trim();

    // Validasi tambahan jika setelah trim jadi kosong
    if (name.isEmpty || email.isEmpty || password.isEmpty || passwordConfirmation.isEmpty) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua field wajib diisi dan tidak boleh hanya spasi.'),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        name,
        email,
        password,
        passwordConfirmation, // Kirim konfirmasi password
      );

      // Navigasi ke HomePage akan dihandle oleh AuthWrapper di main.dart
      // berdasarkan perubahan status di AuthProvider.
      // Jadi, Navigator.pop(context) tidak diperlukan untuk navigasi ke Home.
      // Jika registrasi sukses dan AuthProvider mengubah status, AuthWrapper akan bereaksi.

      if (success && mounted) {
        // Jika ingin kembali ke halaman login setelah register sukses (sebelum AuthWrapper redirect)
        // Anda bisa lakukan pop, tapi biasanya AuthWrapper langsung redirect ke Home.
        Navigator.of(context).pop(); // Opsional: kembali ke login dulu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Anda akan diarahkan ke halaman utama.'),
            backgroundColor: AppColors.greenSuccess,
          ),
        );
        // Biarkan AuthWrapper menangani navigasi ke HomePage
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registrasi Gagal!'),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: ${e.toString().replaceFirst("Exception: ", "")}"),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // void _goBackToLogin() { // Tidak diperlukan jika navigasi "Sudah punya akun?" menggunakan Navigator.pop()
  //   Navigator.pop(context);
  // }

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    // Akan menggunakan style dari AppTheme.inputDecorationTheme
    return InputDecoration(
      hintText: hintText,
      prefixIcon: hintText == 'Username' ? const Icon(Icons.person_outline_rounded, color: AppColors.textLight)
                : hintText == 'Email' ? const Icon(Icons.email_outlined, color: AppColors.textLight)
                : const Icon(Icons.lock_outline_rounded, color: AppColors.textLight),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.background, // Sudah diatur di AppTheme
      body: SafeArea(
        child: Center( // Tambahkan Center
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Register',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 10),
                   Text(
                    'Buat akun baru untuk memulai.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 30),
                  // errorText tidak digunakan lagi, SnackBar lebih baik
                  TextFormField(
                    controller: _nameController, // Menggunakan _nameController
                    decoration: _inputDecoration('Nama Lengkap'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                      if (!value.trim().contains('@') || !value.trim().contains('.')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textLight,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                      if (value.length < 8) return 'Password minimal 8 karakter'; // Sesuai backend
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _repeatPasswordController,
                    obscureText: _obscureRepeatPassword,
                    decoration: _inputDecoration('Konfirmasi Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRepeatPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textLight,
                        ),
                        onPressed: _toggleRepeatPasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                      if (value != _passwordController.text) return 'Password tidak cocok';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _register,
                          child: const Text('REGISTER'),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Sudah punya akun?", style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // Kembali ke halaman sebelumnya (LoginPage)
                        child: Text(
                          'Login Sekarang',
                           style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
