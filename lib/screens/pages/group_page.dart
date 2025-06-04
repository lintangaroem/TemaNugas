import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Sesuaikan path import ini dengan struktur aktual proyek Anda!
import '../../../providers/auth_provider.dart';
import '../../../models/project.dart';
import '../../../constants/constant.dart'; // Dari path Anda: teman_nugas/constants/constant.dart
// import '../../../constants/theme.dart'; // AppTheme biasanya di-apply di main.dart, tidak perlu import di sini kecuali untuk referensi style spesifik yang tidak ada di AppTextStyles/AppColors

// Halaman lain yang mungkin dinavigasi
import './home_page.dart'; // Jika HomePage.dart ada di folder yang sama (lib/screens/pages/)
import 'group_detail_page.dart';
// import './profile.dart'; // Jika ProfilePage ada di folder yang sama

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  @override
  void initState() {
    super.initState();
    // Panggil fetchUserDetails untuk memastikan data proyek pengguna terbaru
    // saat halaman pertama kali dibuka atau menjadi visible.
    // Menggunakan addPostFrameCallback memastikan context sudah siap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ambil AuthProvider dan panggil fetchUserDetails
        // Ini akan memicu pembaruan pada Consumer di build method jika data berubah.
        Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
      }
    });
  }

  Widget _buildProjectListTile(BuildContext context, Project project, {bool isPending = false, bool isCreator = false}) {
    String subtitle = project.description ?? (isPending ? 'Menunggu persetujuan admin proyek' : 'Anggota proyek');
    if (isCreator) {
      subtitle = 'Anda adalah pembuat proyek ini.';
    }
    if (project.deadline != null) {
      subtitle += '\nDeadline: ${DateFormat('dd MMM yy', 'id_ID').format(project.deadline!)}';
    }

    return Card(
      // Styling Card akan diambil dari AppTheme.cardTheme
      child: ListTile(
        // Styling ListTile akan diambil dari AppTheme.listTileTheme
        leading: CircleAvatar(
          backgroundColor: isPending
              ? AppColors.orangeWarning.withOpacity(0.15)
              : (isCreator ? AppColors.greenSuccess.withOpacity(0.15) : AppColors.primaryBlue.withOpacity(0.15)),
          child: Icon(
            isPending ? Icons.hourglass_top_rounded : (isCreator ? Icons.star_outline_rounded : Icons.folder_shared_outlined),
            color: isPending ? AppColors.orangeWarning : (isCreator ? AppColors.greenSuccess : AppColors.primaryBlue),
            size: 22,
          ),
        ),
        title: Text(project.name, style: AppTextStyles.titleMedium),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.labelSmall.copyWith(height: 1.35, color: AppColors.textLight),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isPending
            ? Text("PENDING", style: AppTextStyles.labelSmall.copyWith(color: AppColors.orangeWarning, fontWeight: FontWeight.bold, fontSize: 10))
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        onTap: isPending ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
          ).then((_) {
            // Setelah kembali dari ProjectDetailPage, refresh data user
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
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0, left: 4, right: 4),
      child: Text(title, style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        // Tampilkan loading jika status authenticating dan user belum ada
        if (authProvider.authStatus == AuthStatus.authenticating && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Tampilan jika user tidak ada (seharusnya sudah dihandle AuthWrapper)
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 60, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text("Data pengguna tidak dapat dimuat.", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Coba Lagi Muat Data"),
                    onPressed: () => authProvider.fetchUserDetails(),
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
            automaticallyImplyLeading: false,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // Panggil fetchUserDetails dari AuthProvider untuk memuat ulang data
              // Ini akan memicu rebuild Consumer jika data berubah
              await authProvider.fetchUserDetails();
            },
            child: (user.createdProjects.isEmpty &&
                    followedProjects.isEmpty &&
                    user.pendingProjectRequests.isEmpty)
                ? _buildEmptyState() // Widget untuk tampilan kosong
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                    children: [
                      if (user.createdProjects.isNotEmpty) ...[
                        _buildSectionTitle("Proyek Dibuat Saya (${user.createdProjects.length})"),
                        ...user.createdProjects.map((project) => _buildProjectListTile(context, project, isCreator: true)),
                      ],
                      if (followedProjects.isNotEmpty) ...[
                        _buildSectionTitle("Proyek Diikuti (${followedProjects.length})"),
                        ...followedProjects.map((project) => _buildProjectListTile(context, project)),
                      ],
                      if (user.pendingProjectRequests.isNotEmpty) ...[
                        _buildSectionTitle("Menunggu Persetujuan (${user.pendingProjectRequests.length})"),
                        ...user.pendingProjectRequests.map((project) => _buildProjectListTile(context, project, isPending: true)),
                      ],
                    ],
                  ),
          ),
          // Tidak ada BottomNavigationBar di sini, karena dikelola oleh HomePage
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[350]),
            const SizedBox(height: 24),
            Text(
              "Anda belum terlibat dalam proyek apapun.",
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            Text(
              "Cari proyek di halaman Beranda atau buat proyek baru!",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.explore_outlined),
              label: const Text("Temukan Proyek di Beranda"),
              onPressed: () {
                if (Navigator.canPop(context)) {
                   Navigator.popUntil(context, (route) => route.isFirst);
                } else {
                   Navigator.pushAndRemoveUntil(
                     context,
                     MaterialPageRoute(builder: (context) => const HomePage()), // Asumsi HomePage adalah route utama
                     (route) => false,
                   );
                }
                 // Idealnya, Anda akan memanggil method di HomePage untuk mengubah _selectedIndex
                 //Provider.of<NavigationProvider>(context, listen: false).changeTab(0); // Contoh jika ada NavProvider
              },
            )
          ],
        ),
      ),
    );
  }
}
