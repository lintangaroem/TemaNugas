import 'package:TemaNugas/models/user/authenticated_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:TemaNugas/models/user/authenticated_user.dart';
import '../../../constants/constant.dart'; // Menggunakan path dari kode Anda
import '../../../constants/theme.dart'; // Menggunakan path dari kode Anda
import 'edit_profile.dart';
import '../../widgets/navbar.dart';
import '../../services/API/api_services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 2;
    final ApiService _apiService = ApiService();
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Ambil data user yang sedang login
        final AuthenticatedUser? currentUser = authProvider.user;
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Profil")),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Anda belum login.", style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
          );
        }

        // Jika user sudah login, tampilkan data profilnya
        return Scaffold(
          appBar: AppBar(
            // title: const Text("Profil Saya"), // Judul bisa dihilangkan jika desain lebih minimalis
            backgroundColor: AppColors.background, // Sesuaikan dengan tema
            elevation: 0, // Hilangkan shadow jika desain flat
            automaticallyImplyLeading:
                false, // Tidak ada tombol back jika ini adalah tab utama
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: "Logout",
                onPressed: () async {
                  // Konfirmasi sebelum logout
                  final confirmLogout = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text("Logout"),
                          content: const Text(
                            "Anda yakin ingin keluar dari akun ini?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text("Batal"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                "Logout",
                                style: TextStyle(color: AppColors.redAlert),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirmLogout == true) {
                    await authProvider.logout();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ), // Sesuaikan padding
            child: Center(
              // Pusatkan konten di dalam SingleChildScrollView
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .center, // Pusatkan item secara horizontal
                children: [
                  CircleAvatar(
                    radius: 55, // Sedikit lebih besar
                    backgroundColor: AppColors.lightGrey,
                    // Gunakan NetworkImage dari data user jika ada field avatar
                    // Untuk sekarang, gunakan UI Avatars dengan nama user
                    backgroundImage: NetworkImage(
                      'https://ui-avatars.com/api/?name=${currentUser.name.replaceAll(' ', '+')}&background=random&color=fff&size=128&font-size=0.33',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentUser.name,
                    style:
                        AppTextStyles
                            .headingMedium, // Menggunakan style dari constant
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentUser.email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ), // Menggunakan style dari constant
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Bagian "Skills/Interests" (Chip) - Ini data statis, bisa diubah nanti
                  Wrap(
                    spacing: 8,
                    runSpacing: 4, // Jarak antar baris chip
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
                      // Tambahkan chip lain jika perlu
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
                      );
                    },
                    // Style akan diambil dari AppTheme.elevatedButtonTheme
                    // Jika ingin override:
                    // style: ElevatedButton.styleFrom(
                    //   backgroundColor: AppColors.primaryBlue.withOpacity(0.8),
                    //   padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    // ),
                  ),
                  const SizedBox(height: 32),
                  // Bagian "Bio" - Ini data statis, bisa diubah nanti
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bio Saya',
                      style:
                          AppTextStyles
                              .titleLarge, // Menggunakan style dari constant
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ), // Padding di dalam container bio
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(
                        0.5,
                      ), // Warna lebih soft
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      // Ganti dengan bio pengguna jika ada fieldnya di model User
                      'Mahasiswa semester akhir yang bersemangat dalam pengembangan aplikasi mobile dan web. Tertarik pada kolaborasi untuk proyek-proyek inovatif.',
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                      textAlign: TextAlign.justify, // Agar teks bio lebih rapi
                    ),
                  ),
                  const SizedBox(height: 30), // Padding bawah
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
