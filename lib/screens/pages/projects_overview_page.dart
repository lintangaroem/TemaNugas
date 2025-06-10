import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal jika diperlukan

import '../../providers/auth_provider.dart';
import '../../models/project.dart';
import '../../constants/constant.dart';
import 'homepage/home_page.dart'; // Untuk navigasi kembali ke Beranda
import 'group_detail_page.dart'; // Akan kita buat nanti
// import 'profile_page.dart'; // Untuk navigasi ke profil

class ProjectsOverviewPage extends StatefulWidget {
  const ProjectsOverviewPage({super.key});

  @override
  State<ProjectsOverviewPage> createState() => _ProjectsOverviewPageState();
}

class _ProjectsOverviewPageState extends State<ProjectsOverviewPage> {
  int _selectedIndex = 1; // Index untuk halaman ini di BottomNavBar

  @override
  void initState() {
    super.initState();
    // Panggil fetchUserDetails untuk memastikan data proyek pengguna terbaru saat halaman dibuka
    // listen: false karena ini di initState dan kita tidak ingin rebuild widget ini saat data berubah di sini,
    // melainkan kita akan menggunakan Consumer atau Provider.of(context) di build method.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cek apakah widget masih mounted sebelum memanggil setState atau provider
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Navigasi berdasarkan index
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } else if (index == 1 && _selectedIndex != 1) { // Kembali ke ProjectsOverview dari tab lain (jika ada)
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ProjectsOverviewPage()),
        (Route<dynamic> route) => false,
      );
    } else if (index == 2) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman Profil belum dibuat.')),
      );
    }
    if (mounted && index != _selectedIndex) {
        setState(() {
            _selectedIndex = index;
        });
    }
  }

  Widget _buildProjectListTile(BuildContext context, Project project, {bool isPending = false, bool isCreator = false}) {
    String subtitle = project.description ?? (isPending ? 'Menunggu persetujuan' : 'Anggota proyek');
    if (isCreator) {
      subtitle = 'Anda adalah pembuat proyek ini.';
    }
    if (project.deadline != null) {
      subtitle += '\nDeadline: ${DateFormat('dd MMM yyyy', 'id_ID').format(project.deadline!)}';
    }


    return Card(
      // Menggunakan styling dari AppTheme.cardTheme
      child: ListTile(
        // Menggunakan styling dari AppTheme.listTileTheme
        leading: CircleAvatar(
          backgroundColor: isPending
              ? AppColors.orangeWarning.withAlpha(1)
              : (isCreator ? AppColors.greenSuccess.withAlpha(1) : AppColors.primaryBlue.withAlpha(1)),
          child: Icon(
            isPending ? Icons.hourglass_top_rounded : (isCreator ? Icons.star_border_rounded : Icons.folder_shared_outlined),
            color: isPending ? AppColors.orangeWarning : (isCreator ? AppColors.greenSuccess : AppColors.primaryBlue),
            size: 22,
          ),
        ),
        title: Text(project.name, style: AppTextStyles.titleMedium),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.labelSmall.copyWith(height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isPending
            ? Text("PENDING", style: AppTextStyles.labelSmall.copyWith(color: AppColors.orangeWarning, fontWeight: FontWeight.bold))
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        onTap: isPending ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
          ).then((_) {
            // Setelah kembali dari ProjectDetailPage, refresh data user
            // untuk memastikan daftar proyek terupdate jika ada perubahan
            if (mounted) {
              Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
            }
          });
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kita akan menggunakan Consumer di sini agar UI otomatis rebuild saat data di AuthProvider berubah
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (authProvider.authStatus == AuthStatus.authenticating && user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Proyek Saya")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Proyek Saya")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Silakan login terlebih dahulu.", style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Arahkan ke halaman login
                      // Ini seharusnya tidak terjadi jika AuthWrapper di main.dart sudah benar
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text("Login"),
                  )
                ],
              ),
            ),
          );
        }

        // Filter proyek yang diikuti agar tidak duplikat dengan proyek yang dibuat
        final List<Project> followedProjects = user.approvedProjects
            .where((approvedProject) =>
                !user.createdProjects.any((createdProject) => createdProject.id == approvedProject.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text("Proyek Saya"),
            automaticallyImplyLeading: false, // Tidak ada tombol back jika ini root tab
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await authProvider.fetchUserDetails();
            },
            child: (user.createdProjects.isEmpty &&
                    followedProjects.isEmpty &&
                    user.pendingProjectRequests.isEmpty)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_outlined, size: 70, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            "Anda belum terlibat dalam proyek apapun.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textLight),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Cari proyek di halaman Beranda atau buat proyek baru!",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.home_outlined),
                            label: const Text("Ke Beranda"),
                            onPressed: () => _onItemTapped(0), // Navigasi ke Beranda
                          )
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Proyek yang Dibuat Pengguna
                      if (user.createdProjects.isNotEmpty) ...[
                        _buildSectionTitle("Proyek Dibuat Saya (${user.createdProjects.length})"),
                        ...user.createdProjects.map((project) => _buildProjectListTile(context, project, isCreator: true)),
                      ],

                      // Proyek yang Diikuti (Approved)
                      if (followedProjects.isNotEmpty) ...[
                        _buildSectionTitle("Proyek Diikuti (${followedProjects.length})"),
                        ...followedProjects.map((project) => _buildProjectListTile(context, project)),
                      ],

                      // Permintaan Bergabung yang Pending
                      if (user.pendingProjectRequests.isNotEmpty) ...[
                        _buildSectionTitle("Menunggu Persetujuan (${user.pendingProjectRequests.length})"),
                        ...user.pendingProjectRequests.map((project) => _buildProjectListTile(context, project, isPending: true)),
                      ],
                    ],
                  ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
              BottomNavigationBarItem(icon: Icon(Icons.folder_shared_rounded), label: 'Proyek Saya'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
