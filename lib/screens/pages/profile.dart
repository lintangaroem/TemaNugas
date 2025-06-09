import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/models/user/authenticated_user.dart'; // Sudah ada, tidak perlu import ganda
import '../../../providers/auth_provider.dart';
import '../../../constants/constant.dart';
import '../../../constants/theme.dart';
import 'edit_profile.dart';
import '../../widgets/navbar.dart'; // Pastikan path ini benar!
import 'home_page.dart';
import 'group_page.dart'; // Tambahkan import GroupPage
import 'package:TemaNugas/screens/login/pages/login.dart';


class ProfilePage extends StatefulWidget { // Ubah menjadi StatefulWidget
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> { // Buat State class
  int _selectedIndex = 2; // Pindahkan _selectedIndex ke sini

  void _onItemTapped(int index) { // Pindahkan _onItemTapped ke sini
    if (_selectedIndex == index) return;

    // Perbarui _selectedIndex di state lokal (tidak perlu setState di sini karena navigasi akan mengganti widget)
    // setState(() { _selectedIndex = index; }); // Biasanya tidak perlu karena pushReplacement

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement( // Navigasi ke GroupPage
        context,
        MaterialPageRoute(builder: (ctx) => const GroupPage()),
      );
    } else if (index == 2) {
      // Sudah di ProfilePage, tidak perlu navigasi lagi
      return;
    }
  }

  // initState untuk fetch user details
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pastikan context valid dan widget mounted sebelum menggunakan Provider
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ApiService tidak digunakan di sini, bisa dihapus atau pindahkan jika memang diperlukan di bagian lain
    // final ApiService _apiService = ApiService();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final AuthenticatedUser? currentUser = authProvider.user;

        // Tampilan loading atau jika user belum login
        if (authProvider.authStatus == AuthStatus.authenticating && currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Profil")),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Anda belum login.", style: AppTextStyles.bodyLarge),
                  // Tambahkan tombol untuk ke halaman login jika diperlukan
                ],
              ),
            ),
            bottomNavigationBar: BottomNavBar( // Tetap tampilkan navbar meski belum login (opsional, tergantung UX)
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        }

        // Jika user sudah login, tampilkan data profilnya
        return Scaffold(
          appBar: AppBar(
            // title: const Text("Profil Saya"),
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined, color: AppColors.primaryBlue),
                tooltip: "Logout",
                onPressed: () async {
                  if (!mounted) return;

                  // Show a confirmation dialog before logging out
                  final confirmLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false), // User cancels
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true), // User confirms
                          child: const Text(
                            "Yes",
                            style: TextStyle(color: AppColors.redAlert),
                          ),
                        ),
                      ],
                    ),
                  );

                  // If the user confirms the logout, proceed
                  if (confirmLogout == true) {
                    await Provider.of<AuthProvider>(context, listen: false).logout();

                    // After logout, navigate to the login page
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false, // Remove all routes in the stack
                    );
                  }
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=${currentUser.name.replaceAll(' ', '+')}&background=random&color=fff&size=128&font-size=0.33',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentUser.name,
                    style: AppTextStyles.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentUser.email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: const [
                      Chip(
                        label: Text('UI/UX'),
                        backgroundColor: AppColors.lightGrey,
                      ),
                      Chip(
                        label: Text('Frontend'),
                        backgroundColor: AppColors.lightGrey,
                      ),
                      Chip(
                        label: Text('Backend'),
                        backgroundColor: AppColors.lightGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Edit Profil'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      ).then((_) {
                        // Setelah kembali dari EditProfilePage, refresh data user
                        if (mounted) {
                          Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bio Saya',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mahasiswa semester akhir yang bersemangat dalam pengembangan aplikasi mobile dan web. Tertarik pada kolaborasi untuk proyek-proyek inovatif.',
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          // Tambahkan ini untuk menampilkan navbar!
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}