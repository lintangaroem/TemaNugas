import 'package:flutter/material.dart';
import 'package:teman_nugas/constants/constant.dart'; // Pastikan file constant.dart berada di lokasi yang benar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Untuk BottomNavigationBar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Tambahkan navigasi ke halaman lain di sini jika diperlukan
      // if (index == 1) { Navigator.pushNamed(context, '/group'); }
      // if (index == 2) { Navigator.pushNamed(context, '/profile'); }
    });
  }

  // --- Dialog Tambah Proyek ---
  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Project Name", style: AppTextStyles.heading),
          content: SingleChildScrollView( // Menggunakan SingleChildScrollView jika kontennya panjang
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTextField("Project Name"), // Akan menggunakan nama proyek sebagai judul dialog
                const SizedBox(height: 16),
                _buildTextField("Deadline"),
                const SizedBox(height: 16),
                _buildTextField("Members"),
                const SizedBox(height: 16),
                _buildTextField("Description", maxLines: 3),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("CANCEL", style: TextStyle(color: AppColors.redAlert)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.background,
              ),
              child: const Text("ADD"),
              onPressed: () {
                // Logika untuk menambah proyek
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String labelText, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppTextStyles.regular.copyWith(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }

  // --- Dialog Konfirmasi Join ---
  void _showJoinConfirmationDialog(BuildContext context, String projectName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                projectName,
                style: AppTextStyles.heading.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Anggota : 1/5", // Contoh data
                style: AppTextStyles.regular.copyWith(color: Colors.grey[700]),
              ),
              Text(
                "Deadline : 17 Agustus 2026", // Contoh data
                style: AppTextStyles.regular.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                "Membuat aplikasi task management tugas berbasis haha hihi huhuhu hehe", // Contoh deskripsi panjang
                style: AppTextStyles.regular.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Apakah kamu yakin untuk join?",
                style: AppTextStyles.content.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.redAlert,
                        side: const BorderSide(color: AppColors.redAlert),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("CANCEL"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.background,
                      ),
                      child: const Text("JOIN"),
                      onPressed: () {
                        // Logika untuk bergabung dengan proyek
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              // --- Bagian Atas (Profil Pengguna) ---
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    // Ganti dengan gambar profil pengguna jika ada
                    backgroundImage: NetworkImage('https://via.placeholder.com/150/0000FF/808080?Text=User'),
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Halo, Salma!", style: AppTextStyles.heading.copyWith(fontSize: 18)),
                      Text(
                        "Siap nugas bareng hari ini?",
                        style: AppTextStyles.regular.copyWith(color: Colors.grey[600]),
                      ),
                      Text(
                        "3 projects remain", // Contoh data
                        style: AppTextStyles.regular.copyWith(fontSize: 10, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // --- Search Project ---
              TextField(
                decoration: InputDecoration(
                  hintText: "Search Project",
                  hintStyle: AppTextStyles.regular.copyWith(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- Daftar Proyek ---
              Expanded(
                child: ListView.builder(
                  itemCount: 3, // Jumlah proyek (contoh)
                  itemBuilder: (context, index) {
                    // Anda bisa mengganti ini dengan data proyek yang sebenarnya
                    String projectName = "Sistem Informasi Geografis";
                    if (index == 1) projectName = "Aplikasi Mobile E-commerce";
                    if (index == 2) projectName = "Website Portfolio Pribadi";

                    return ProjectCard(
                      projectName: projectName,
                      memberCount: "1/5",
                      deadline: "17 Agustus 2026",
                      description: "Membuat aplikasi task management...",
                      onJoin: () {
                        _showJoinConfirmationDialog(context, projectName);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProjectDialog(context);
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.background,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Sesuai gambar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Group',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey[500],
        onTap: _onItemTapped,
        backgroundColor: AppColors.background,
        elevation: 8.0, // Memberi sedikit bayangan
        type: BottomNavigationBarType.fixed, // Agar semua label terlihat
        selectedLabelStyle: AppTextStyles.regular.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: AppTextStyles.regular.copyWith(fontSize: 10),
      ),
    );
  }
}

// --- Widget untuk Kartu Proyek ---
class ProjectCard extends StatelessWidget {
  final String projectName;
  final String memberCount;
  final String deadline;
  final String description;
  final VoidCallback onJoin;

  const ProjectCard({
    super.key,
    required this.projectName,
    required this.memberCount,
    required this.deadline,
    required this.description,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[300]!, width: 0.5),
      ),
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(projectName, style: AppTextStyles.content.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.group_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text("Anggota : $memberCount", style: AppTextStyles.regular.copyWith(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text("Deadline : $deadline", style: AppTextStyles.regular.copyWith(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.regular.copyWith(fontSize: 12, color: Colors.grey[800]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  textStyle: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w500, fontSize: 13)
                ),
                child: const Text("JOIN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}