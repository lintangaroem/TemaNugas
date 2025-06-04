import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teman_nugas/constants/theme.dart'; // Sesuaikan path jika berbeda
import 'package:teman_nugas/providers/auth_provider.dart'; // Sesuaikan path jika berbeda
import 'package:teman_nugas/screens/login/pages/login.dart'; // Sesuaikan path jika berbeda
import 'package:teman_nugas/screens/login/pages/register.dart';

// Import untuk initializeDateFormatting
import 'package:intl/date_symbol_data_local.dart'; // Perhatikan path ini mungkin berbeda tergantung versi intl
// Atau coba: import 'package:intl/intl_browser.dart'; jika untuk web, atau cukup 'package:intl/date_symbol_data_local.dart';

// Untuk format tanggal Indonesia di DatePicker dan lainnya
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teman_nugas/screens/pages/home_page.dart';

// Fungsi main sekarang menjadi async untuk await initializeDateFormatting
Future<void> main() async { // Tambahkan async
  // Pastikan Flutter binding diinisialisasi jika ada operasi async sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data formatting untuk locale yang akan digunakan
  // Anda bisa menginisialisasi untuk locale default atau beberapa locale
  // 'id_ID' untuk Bahasa Indonesia
  await initializeDateFormatting('id_ID', null); // Tambahkan await

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Tambahkan provider lain di sini jika diperlukan nanti
        // misal: ProjectProvider, TodoProvider
      ],
      child: MaterialApp(
        title: 'Teman Nugas',
        theme: AppTheme.lightTheme, // Menggunakan tema dari app_theme.dart
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [ // Untuk format tanggal Indonesia
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [ // Untuk format tanggal Indonesia
          Locale('id', 'ID'), // Bahasa Indonesia
          Locale('en', 'US'), // Bahasa Inggris sebagai fallback
        ],
        locale: const Locale('id', 'ID'), // Set default locale ke Indonesia
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          // '/register': (context) => RegisterPage(),
          // '/projects_overview': (context) => ProjectsOverviewPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().authStatus;

    print("AuthWrapper: Current AuthStatus = $authStatus");

    switch (authStatus) {
      case AuthStatus.uninitialized:
      case AuthStatus.authenticating:
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
      case AuthStatus.authenticated:
        return const HomePage();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      default:
        return const LoginPage();
    }
  }
}
