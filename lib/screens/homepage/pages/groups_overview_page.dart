// lib/ui/screens/groups_overview_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/group.dart';
import '../../../constants/constant.dart';
import 'homepage.dart'; // Untuk navigasi kembali ke home
// import 'profile_page.dart'; // Untuk navigasi ke profil
// import 'group_detail_page.dart'; // Akan dibuat nanti

class GroupsOverviewPage extends StatefulWidget {
  const GroupsOverviewPage({super.key});

  @override
  State<GroupsOverviewPage> createState() => _GroupsOverviewPageState();
}

class _GroupsOverviewPageState extends State<GroupsOverviewPage> {
  int _selectedIndex = 1; // Index untuk halaman ini di BottomNavBar

  @override
  void initState() {
    super.initState();
    // Panggil fetchUserDetails untuk memastikan data grup user terbaru
    // listen: false karena ini di initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
    });
  }

  void _onItemTapped(int index) {
     if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 2) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman Profil belum dibuat.')),
      );
    }
  }

  Widget _buildGroupListTile(Group group, {bool isPending = false, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: isPending ? Colors.orange.shade100 : AppColors.primaryBlue.withOpacity(0.15),
          child: Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.group_rounded,
            color: isPending ? Colors.orange.shade700 : AppColors.primaryBlue,
          ),
        ),
        title: Text(group.name, style: AppTextStyles.content.copyWith(fontSize: 16)),
        subtitle: Text(
          group.description ?? (isPending ? 'Menunggu persetujuan admin grup' : 'Anggota grup'),
          style: AppTextStyles.regular.copyWith(fontSize: 13, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isPending
            ? Text("PENDING", style: AppTextStyles.regular.copyWith(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 11))
            : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: isPending ? null : () {
          // Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailPage(groupId: group.id)));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Halaman Detail Grup untuk "${group.name}" belum dibuat.')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      // Seharusnya tidak terjadi jika navigasi sudah benar
      return Scaffold(
        appBar: AppBar(title: const Text("Grup Saya")),
        body: const Center(child: Text("Silakan login terlebih dahulu.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grup Saya", style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        elevation: 1,
        automaticallyImplyLeading: false, // Tidak ada tombol back jika ini root tab
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.fetchUserDetails();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (user.approvedGroups.isEmpty && user.pendingGroupRequests.isEmpty && user.createdGroups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_meeting_room_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "Anda belum bergabung atau membuat grup.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.regular.copyWith(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                       Text(
                        "Cari grup di halaman Beranda atau buat grup baru!",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.regular.copyWith(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),

            // Grup yang dibuat pengguna
            if (user.createdGroups.isNotEmpty) ...[
              Text("Grup Dibuat Saya", style: AppTextStyles.heading.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              ...user.createdGroups.map((group) => _buildGroupListTile(group, onTap: () {
                // Navigasi ke detail grup dengan kemampuan admin
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Halaman Admin Grup untuk "${group.name}" belum dibuat.')),
                );
              })),
              const SizedBox(height: 24),
            ],


            // Grup yang diikuti (approved)
            if (user.approvedGroups.where((ag) => !user.createdGroups.any((cg) => cg.id == ag.id)).isNotEmpty) ...[
               Text("Grup Diikuti", style: AppTextStyles.heading.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              // Filter agar tidak menampilkan grup yang sudah ada di "Grup Dibuat Saya"
              ...user.approvedGroups
                  .where((approvedGroup) => !user.createdGroups.any((createdGroup) => createdGroup.id == approvedGroup.id))
                  .map((group) => _buildGroupListTile(group)),
              const SizedBox(height: 24),
            ],


            // Permintaan Bergabung yang Pending
            if (user.pendingGroupRequests.isNotEmpty) ...[
              Text("Menunggu Persetujuan", style: AppTextStyles.heading.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              ...user.pendingGroupRequests.map((group) => _buildGroupListTile(group, isPending: true)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_rounded), label: 'Grup Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey[500],
        onTap: _onItemTapped,
        backgroundColor: AppColors.background,
        elevation: 8.0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.regular.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.regular.copyWith(fontSize: 11),
      ),
    );
  }
}
