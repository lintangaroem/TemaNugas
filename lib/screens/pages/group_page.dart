import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal jika diperlukan

// Sesuaikan path import ini dengan struktur proyek Anda
import '../../../providers/auth_provider.dart';
import '../../../models/project.dart';
import '../../../constants/constant.dart'; // Menggunakan path dari kode Anda
import '../../../constants/theme.dart';   // Menggunakan path dari kode Anda

// Halaman lain yang mungkin dinavigasi
import 'home_page.dart'; // Asumsi HomePage ada di lib/ui/screens/ atau lib/screens/
import './group_detail_page.dart'; // Akan kita buat nanti di folder yang sama (pages)
// import './profile.dart'; // Jika ProfilePage ada di folder yang sama

class GroupPage extends StatefulWidget { // Menggunakan nama class GroupPage
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  // _selectedIndex tidak diperlukan di sini karena BottomNav dikelola oleh HomePage

  @override
  void initState() {
    super.initState();
    // Panggil fetchUserDetails untuk memastikan data proyek pengguna terbaru saat halaman dibuka
    // listen: false karena ini di initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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
      // Menggunakan format 'dd MMM yy' agar lebih ringkas jika subtitle panjang
      subtitle += '\nDeadline: ${DateFormat('dd MMM yy', 'id_ID').format(project.deadline!)}';
    }

    return Card(
      // elevation dan shape akan diambil dari AppTheme.cardTheme
      // margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0), // Sudah di AppTheme
      child: ListTile(
        // styling akan diambil dari AppTheme.listTileTheme
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
        title: Text(project.name, style: AppTextStyles.titleMedium), // Menggunakan AppTextStyles
        subtitle: Text(
          subtitle,
          style: AppTextStyles.labelSmall.copyWith(height: 1.35, color: AppColors.textLight), // Menggunakan AppTextStyles
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
      child: Text(title, style: AppTextStyles.headingMedium.copyWith(fontSize: 18)), // Menggunakan AppTextStyles
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer agar UI otomatis rebuild saat data di AuthProvider berubah
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (authProvider.authStatus == AuthStatus.authenticating && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (user == null) {
          return Center( // Tampilan jika user belum termuat (seharusnya jarang terjadi jika AuthWrapper bekerja)
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 60, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text("Data pengguna tidak tersedia.", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Coba Lagi"),
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

        // Menggunakan Scaffold di sini karena GroupPage adalah halaman mandiri yang ditampilkan oleh IndexedStack di HomePage
        // Jika HomePage tidak memiliki AppBar saat GroupPage aktif, maka AppBar di sini akan muncul.
        return Scaffold(
          appBar: AppBar(
            title: const Text("Proyek Saya"), // Akan menggunakan style dari AppTheme
            automaticallyImplyLeading: false, // Tidak ada tombol back otomatis
            // centerTitle: true, // Sudah diatur di AppTheme
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await authProvider.fetchUserDetails();
            },
            child: (user.createdProjects.isEmpty &&
                    followedProjects.isEmpty &&
                    user.pendingProjectRequests.isEmpty)
                ? Center( // Tampilan jika tidak ada proyek sama sekali
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
                            icon: const Icon(Icons.explore_outlined), // Ikon lebih relevan
                            label: const Text("Temukan Proyek"),
                            onPressed: () {
                               // Navigasi ke HomePage (index 0)
                               // Ini akan dihandle oleh BottomNav di HomePage.
                               // Jika ingin aksi tombol, pastikan HomePage dapat diakses dan
                               // BottomNav di HomePage diupdate indexnya.
                               // Untuk sekarang, ini hanya contoh.
                               if (Navigator.canPop(context)) { // Jika halaman ini di-push, bisa pop
                                  Navigator.popUntil(context, (route) => route.isFirst);
                               } else { // Jika ini root dari Navigator (misal setelah pushReplacement)
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const HomePage()), // Asumsi HomePage adalah route utama
                                    (route) => false,
                                  );
                               }
                               // Idealnya, BottomNav di HomePage yang mengontrol ini.
                            },
                          )
                        ],
                      ),
                    ),
                  )
                : ListView( // Tampilan jika ada proyek
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding bawah agar tidak tertutup BottomNav
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
          // BottomNavigationBar tidak diperlukan di sini jika GroupPage adalah salah satu
          // halaman yang ditampilkan oleh IndexedStack di HomePage yang sudah punya BottomNav.
        );
      },
    );
  }
}
