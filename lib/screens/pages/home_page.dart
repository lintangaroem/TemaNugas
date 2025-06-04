import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:teman_nugas/widgets/project_card.dart';

import '../../constants/constant.dart';
import '../../models/project.dart';
import '../../models/user/authenticated_user.dart';
import '../../services/api/api_services.dart';
import '../../providers/auth_provider.dart';
//import '../../widgets/project_card.dart';
import 'group_detail_page.dart';
import 'projects_overview_page.dart'; // Akan kita buat
// import 'profile_page.dart'; // Akan kita buat

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  Future<List<Project>>? _discoverableProjectsFuture;
  AuthenticatedUser? _currentUser;

  // Untuk search
  String _searchQuery = '';
  List<Project> _allProjects = [];
  List<Project> _filteredProjects = [];

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _loadDiscoverableProjects();
    // Tambahkan listener untuk refresh data user jika AuthProvider diperbarui
    // Provider.of<AuthProvider>(context, listen: false).addListener(_updateCurrentUser);
  }

  // void _updateCurrentUser() {
  //   if (mounted) {
  //     setState(() {
  //       _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
  //     });
  //   }
  // }

  @override
  void dispose() {
    // Provider.of<AuthProvider>(context, listen: false).removeListener(_updateCurrentUser);
    super.dispose();
  }

  void _loadDiscoverableProjects() {
    setState(() {
      _discoverableProjectsFuture = _apiService.getDiscoverableProjects();
      // Setelah data diambil, simpan ke _allProjects dan filter
      _discoverableProjectsFuture?.then((projects) {
        if (mounted) {
          setState(() {
            _allProjects = projects;
            _filterProjects();
          });
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat proyek: ${error.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
          );
        }
      });
    });
  }

  void _filterProjects() {
    if (_searchQuery.isEmpty) {
      _filteredProjects = List.from(_allProjects);
    } else {
      _filteredProjects = _allProjects
          .where((project) =>
              project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (project.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    // setState(() {}); // Tidak perlu setState eksplisit jika dipanggil dari onChanged atau setelah _loadDiscoverableProjects
  }


  void _onItemTapped(int index) {
    if (index == _selectedIndex && index != 0) return; // Hindari rebuild jika tab sama kecuali home

    // Navigasi berdasarkan index
    if (index == 0 && _selectedIndex !=0) { // Kembali ke Home dari tab lain
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false, // Hapus semua route sebelumnya
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProjectsOverviewPage()),
      );
    } else if (index == 2) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman Profil belum dibuat.')),
      );
    }
     if (mounted && index != _selectedIndex) { // Hanya set state jika index berubah
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showCreateProjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String projectName = '';
    String projectDescription = '';
    DateTime? projectDeadline;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Buat Proyek Baru"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Nama Proyek*"),
                        validator: (value) => (value == null || value.isEmpty) ? 'Nama proyek tidak boleh kosong' : null,
                        onSaved: (value) => projectName = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Deskripsi Proyek (Opsional)"),
                        maxLines: 3,
                        onSaved: (value) => projectDescription = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      Text("Deadline Proyek (Opsional)", style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: projectDeadline ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)), // Izinkan memilih tanggal lalu
                            lastDate: DateTime(2101),
                            helpText: 'PILIH TANGGAL DEADLINE',
                            builder: (context, child) { // Theming date picker
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primaryBlue, // header background color
                                    onPrimary: Colors.white, // header text color
                                    onSurface: AppColors.textDark, // body text color
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryBlue, // button text color
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != projectDeadline) {
                            setDialogState(() => projectDeadline = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                projectDeadline == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMMM yyyy', 'id_ID').format(projectDeadline!),
                                style: AppTextStyles.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("BATAL"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text("BUAT PROYEK"),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      // Tampilkan loading
                      showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
                      try {
                        final newProject = await _apiService.createProject(projectName, projectDescription, projectDeadline);
                        Navigator.of(context).pop(); // Tutup loading
                        Navigator.of(context).pop(); // Tutup dialog utama
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Proyek "${newProject.name}" berhasil dibuat!'), backgroundColor: AppColors.greenSuccess),
                        );
                        _loadDiscoverableProjects(); // Refresh daftar proyek
                        Provider.of<AuthProvider>(context, listen: false).fetchUserDetails(); // Refresh data user
                      } catch (e) {
                        Navigator.of(context).pop(); // Tutup loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRequestJoinConfirmationDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(project.name, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                project.description ?? "Tidak ada deskripsi.",
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              const Text(
                "Anda akan mengirim permintaan untuk bergabung dengan proyek ini. Lanjutkan?",
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              child: const Text("BATAL"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("KIRIM PERMINTAAN"),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _apiService.requestToJoinProject(project.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Permintaan bergabung ke "${project.name}" terkirim!'), backgroundColor: AppColors.greenSuccess),
                  );
                  Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: _currentUser?.name != null
                        ? NetworkImage('https://ui-avatars.com/api/?name=${_currentUser!.name.replaceAll(' ', '+')}&background=random&color=fff&size=128')
                        : null,
                    child: _currentUser?.name == null ? const Icon(Icons.person, size: 28, color: AppColors.textLight) : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Halo, ${_currentUser?.name ?? 'Pengguna'}!",
                          style: AppTextStyles.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Siap nugas bareng hari ini?",
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: AppColors.primaryBlue),
                    tooltip: "Logout",
                    onPressed: () async {
                      await Provider.of<AuthProvider>(context, listen: false).logout();
                      // Navigasi akan dihandle oleh AuthWrapper di main.dart
                    },
                  )
                ],
              ),
              const SizedBox(height: 25),
              TextField(
                decoration: const InputDecoration(
                  hintText: "Cari Proyek...",
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterProjects();
                  });
                },
              ),
              const SizedBox(height: 25),
              Text("Temukan Proyek", style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Project>>(
                  future: _discoverableProjectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.redAlert)));
                    } else if (!snapshot.hasData || _filteredProjects.isEmpty && _searchQuery.isEmpty) { // Cek _filteredProjects jika tidak ada query
                       return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                            const SizedBox(height:10),
                            Text("Belum ada proyek tersedia.", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)),
                            const SizedBox(height:5),
                            Text("Coba buat proyek baru!", style: AppTextStyles.bodyMedium),
                          ],
                        )
                      );
                    } else if (_filteredProjects.isEmpty && _searchQuery.isNotEmpty) {
                       return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                            const SizedBox(height:10),
                            Text("Proyek \"$_searchQuery\" tidak ditemukan.", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)),
                          ],
                        )
                      );
                    }

                    // Tampilkan _filteredProjects
                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadDiscoverableProjects();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding agar tidak tertutup FAB
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          return ProjectCard(
                            project: project,
                            onRequestJoinPressed: () {
                              _showRequestJoinConfirmationDialog(context, project);
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
                              ).then((_) => _loadDiscoverableProjects()); // Refresh saat kembali
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateProjectDialog(context);
        },
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text("BUAT PROYEK"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_outlined), label: 'Proyek Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
