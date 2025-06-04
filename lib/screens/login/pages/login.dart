import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Sesuaikan path ini jika lokasi file berbeda di proyek Anda
import '../../../providers/auth_provider.dart';
import '../../../constants/constant.dart'; // Menggunakan path dari kode Anda
import '../../../constants/theme.dart';   // Menggunakan path dari kode Anda
import 'register.dart'; // Import untuk halaman register
// HomePage tidak perlu diimport di sini lagi jika navigasi dihandle AuthWrapper
// import '../../pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // .trim() sudah ada, bagus!
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // Validasi tambahan jika setelah trim jadi kosong (meskipun validator sudah ada)
    if (email.isEmpty || password.isEmpty) {
      if (mounted) { // Selalu cek mounted sebelum mengakses context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email dan Password tidak boleh hanya spasi.'),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(email, password);

      // Navigasi ke HomePage akan dihandle oleh AuthWrapper di main.dart
      // berdasarkan perubahan status di AuthProvider.
      // Jadi, tidak perlu Navigator.pushReplacement di sini.

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login Gagal! Periksa kembali email dan password Anda.'),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
    } catch (e) {
      // Error dari API service (misal koneksi, dll) akan ditangkap di sini
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil tema dari AppTheme
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: AppColors.background, // Sudah diatur di AppTheme
      body: SafeArea(
        child: Center( // Tambahkan Center agar form di tengah jika konten tidak memenuhi layar
          child: SingleChildScrollView( // Memastikan bisa di-scroll jika keyboard muncul
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten kolom
                crossAxisAlignment: CrossAxisAlignment.stretch, // Buat tombol full-width
                children: [
                  // Anda bisa menambahkan logo atau gambar di sini
                  const SizedBox(height: 20),
                  Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(color: AppColors.primaryBlue), // Menggunakan AppTextStyles
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selamat datang kembali! Silakan login.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration( // Akan menggunakan style dari AppTheme.inputDecorationTheme
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textLight),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                      if (!value.trim().contains('@') || !value.trim().contains('.')) { // Validasi email sederhana
                        return 'Masukkan format email yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textLight),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textLight,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implementasi Lupa Password
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur Lupa Password belum diimplementasikan.')),
                        );
                      },
                      child: Text( // Akan menggunakan style dari AppTheme.textButtonTheme
                        'Lupa password?',
                        // style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25), // Beri jarak sebelum tombol login
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          // Style akan diambil dari AppTheme.elevatedButtonTheme
                          onPressed: _submit,
                          child: const Text('LOGIN'),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Belum punya akun?", style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          'Daftar Sekarang',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Padding bawah
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
