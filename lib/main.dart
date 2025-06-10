import 'package:TemaNugas/screens/pages/homepage/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/constants/theme.dart'; // Sesuaikan path jika berbeda
import 'package:TemaNugas/providers/auth_provider.dart'; // Sesuaikan path jika berbeda
import 'package:TemaNugas/screens/login/pages/login.dart';
import 'package:TemaNugas/screens/login/pages/register.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  // Tambahkan async
  // Pastikan Flutter binding diinisialisasi jika ada operasi async sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Teman Nugas',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        locale: const Locale('id', 'ID'),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/register': (context) => const RegisterPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final authStatus = authProvider.authStatus;
        
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
            print("AuthWrapper: User is authenticated, showing HomePage");
            return const HomePage();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
          default:
            print("AuthWrapper: User is not authenticated, showing LoginPage");
            return const LoginPage();
        }
      },
    );
  }
}
