// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:teman_nugas/constants/constant.dart'; // Pastikan path ini benar
import 'package:teman_nugas/constants/theme.dart'; // Pastikan path ini benar
import 'screens/homepage/pages/homepage.dart'; // Akan kita buat/update
import 'screens/login/pages/login.dart'; // Akan kita buat
// import 'ui/screens/splash_screen.dart'; // Opsional untuk loading awal

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Tambahkan provider lain di sini jika perlu (misal: GroupProvider)
      ],
      child: MaterialApp(
        title: 'Teman Nugas App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            switch (auth.authStatus) {
              case AuthStatus.uninitialized:
              // Tampilkan splash screen yang lebih baik atau loading indicator yang jelas
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text("Memuat aplikasi..."),
                      ],
                    ),
                  ),
                );
              case AuthStatus.authenticating:
                return const Scaffold( // Atau splash screen yang sama
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text("Sedang memeriksa sesi..."),
                      ],
                    ),
                  ),
                );
              case AuthStatus.authenticated:
                return const HomePage();
              case AuthStatus.unauthenticated:
              case AuthStatus.error: // Anda bisa buat halaman error khusus jika mau
              default:
                return const LoginPage();
            }
          },
        ),
        // Definisikan routes jika Anda menggunakan navigasi berbasis nama
        // routes: {
        //   '/login': (context) => LoginPage(),
        //   '/home': (context) => HomePage(),
        //   // ...
        // },
      ),
    );
  }
}
