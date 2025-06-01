// lib/ui/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../constants/constant.dart'; // Sesuaikan path jika perlu
// import 'register_page.dart'; // Akan dibuat nanti

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Ini tidak terlalu penting jika Anda langsung pakai .text
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // === TAMBAHKAN .trim() DI SINI ===
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim(); // Password juga di-trim, meskipun jarang ada spasi di password

    // Periksa apakah setelah trim, string tidak kosong (jika validasi awal tidak menangkapnya)
    if (email.isEmpty || password.isEmpty) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Email dan Password tidak boleh hanya spasi.'),
                    backgroundColor: AppColors.redAlert,
                ),
            );
            setState(() {
                _isLoading = false;
            });
        }
        return;
    }


    try {
      // Kirim value yang sudah di-trim
      bool success = await authProvider.login(email, password);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login Gagal!'),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
      // Navigasi akan dihandle oleh Consumer di main.dart
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst("Exception: ", "")),
            backgroundColor: AppColors.redAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Selamat Datang!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(fontSize: 28, color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login untuk melanjutkan ke Teman Nugas',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular.copyWith(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: AppTextStyles.content.copyWith(fontSize: 18, fontWeight: FontWeight.w500)
                        ),
                        onPressed: _submit,
                        child: const Text('LOGIN'),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun?", style: AppTextStyles.regular.copyWith(fontSize: 14)),
                    TextButton(
                      onPressed: () {
                        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Halaman registrasi belum dibuat.')),
                        );
                      },
                      child: Text(
                        'Daftar Sekarang',
                        style: AppTextStyles.regular.copyWith(fontSize: 14, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
