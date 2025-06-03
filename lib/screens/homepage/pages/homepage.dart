// lib/ui/screens/homepage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

import 'package:teman_nugas/constants/constant.dart';
import '../../../models/group.dart';
import '../../../models/user/authenticated_user.dart';
import '../../../services/API/api_services.dart'; // Kita akan pakai service
import '../../../providers/auth_provider.dart';
import '../widgets/group_card.dart'; // Widget kartu grup baru
import 'groups_overview_page.dart'; // Halaman grup saya
// import 'profile_page.dart'; // Halaman profil

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Untuk BottomNavigationBar
  final ApiService _apiService = ApiService(); // Instance API service
  Future<List<Group>>? _discoverableGroupsFuture;
  AuthenticatedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    // Ambil data user saat ini dari AuthProvider
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _loadDiscoverableGroups();
  }

  void _loadDiscoverableGroups() {
    setState(() {
      _discoverableGroupsFuture = _apiService.getDiscoverableGroups();
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Hindari rebuild jika tab sama

    setState(() {
      _selectedIndex = index;
    });

    // Navigasi berdasarkan index
    // HomePage adalah index 0, jadi tidak perlu navigasi jika kembali ke sini
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GroupsOverviewPage()),
      );
    } else if (index == 2) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman Profil belum dibuat.')),
      );
    }
  }

  // --- Dialog Buat Grup Baru ---
  void _showCreateGroupDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String groupName = '';
    String groupDescription = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Buat Grup Baru", style: AppTextStyles.heading),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Nama Grup",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama grup tidak boleh kosong';
                      }
                      return null;
                    },
                    onSaved: (value) => groupName = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Deskripsi Grup (Opsional)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    onSaved: (value) => groupDescription = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "BATAL",
                style: TextStyle(color: AppColors.redAlert),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("BUAT GRUP"),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  try {
                    final newGroup = await _apiService.createGroup(
                      groupName,
                      groupDescription,
                    );
                    Navigator.of(context).pop(); // Tutup dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Grup "${newGroup.name}" berhasil dibuat!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh daftar grup atau navigasi ke halaman grup baru
                    // Untuk sekarang, kita refresh daftar discoverable groups (meski idealnya ada state management yang lebih baik)
                    _loadDiscoverableGroups();
                    // Mungkin juga mau refresh data user di AuthProvider jika createGroup otomatis menambahkan user
                    Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).fetchUserDetails();
                  } catch (e) {
                    Navigator.of(context).pop(); // Tutup dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal membuat grup: ${e.toString().replaceFirst("Exception: ", "")}',
                        ),
                        backgroundColor: AppColors.redAlert,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCreateFullProjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String projectName = '';
    String projectDescription = '';
    DateTime? projectDeadline;
    String groupName = '';
    String groupDescription = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Untuk update tanggal di dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Buat Proyek Baru",
                style: AppTextStyles.heading,
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Detail Proyek",
                        style: AppTextStyles.content.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Nama Proyek*",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Nama proyek tidak boleh kosong'
                                    : null,
                        onSaved: (value) => projectName = value!,
                        onChanged: (value) {
                          // Otomatis isi nama grup jika kosong
                          if (groupName.isEmpty ||
                              groupName ==
                                  projectName.substring(
                                    0,
                                    projectName.length > 0
                                        ? projectName.length - 1
                                        : 0,
                                  )) {
                            // Cek jika groupName masih kosong atau sama dengan projectName sebelumnya
                            setDialogState(() {
                              // Perlu setDialogState jika mau update UI lain di dialog
                              // Ini hanya contoh, mungkin perlu controller untuk TextFormField groupName
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Deskripsi Proyek (Opsional)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                        onSaved: (value) => projectDescription = value ?? '',
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: projectDeadline ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != projectDeadline) {
                            setDialogState(() => projectDeadline = picked);
                          }
                        },
                        child: Container(
                          /* ... UI Date Picker seperti sebelumnya ... */
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                projectDeadline == null
                                    ? 'Deadline Proyek (Opsional)'
                                    : DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(projectDeadline!),
                                style: AppTextStyles.regular.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24, thickness: 1),
                      Text(
                        "Detail Grup untuk Proyek Ini",
                        style: AppTextStyles.content.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        // controller: _groupNameController, // Gunakan controller jika ingin prefill dinamis
                        initialValue:
                            groupName, // Atau prefill dari projectName
                        decoration: InputDecoration(
                          labelText: "Nama Grup*",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Nama grup tidak boleh kosong'
                                    : null,
                        onSaved: (value) => groupName = value!,
                        onChanged:
                            (value) =>
                                groupName = value, // Simpan perubahan langsung
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Deskripsi Grup (Opsional)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                        onSaved: (value) => groupDescription = value ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    "BATAL",
                    style: TextStyle(color: AppColors.redAlert),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text("BUAT PROYEK & GRUP"),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      // Tampilkan loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (ctx) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );

                      try {
                        final newProject = await _apiService.createFullProject(
                          projectName,
                          projectDescription,
                          projectDeadline,
                          groupName,
                          groupDescription,
                        );
                        Navigator.of(context).pop(); // Tutup loading
                        Navigator.of(context).pop(); // Tutup dialog utama
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Proyek "${newProject.name}" dalam grup "${newProject.group?.name ?? groupName}" berhasil dibuat!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadDiscoverableGroups(); // Refresh daftar grup di homepage
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).fetchUserDetails(); // Refresh data user
                      } catch (e) {
                        Navigator.of(context).pop(); // Tutup loading
                        // Jangan tutup dialog utama agar user bisa koreksi
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal: ${e.toString().replaceFirst("Exception: ", "")}',
                            ),
                            backgroundColor: AppColors.redAlert,
                          ),
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

  // --- Dialog Konfirmasi Request Join ---
  void _showJoinConfirmationDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            group.name,
            style: AppTextStyles.heading.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                group.description ?? "Tidak ada deskripsi.",
                style: AppTextStyles.regular.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Text(
                "Anda akan mengirim permintaan untuk bergabung dengan grup ini. Lanjutkan?",
                style: AppTextStyles.content.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              child: const Text(
                "BATAL",
                style: TextStyle(color: AppColors.redAlert),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("KIRIM PERMINTAAN"),
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi dulu
                try {
                  await _apiService.requestToJoinGroup(group.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Permintaan bergabung ke "${group.name}" terkirim!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh data user untuk update pending requests
                  Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).fetchUserDetails();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                      backgroundColor: AppColors.redAlert,
                    ),
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
    // Dapatkan user dari AuthProvider untuk personalisasi
    // final authProvider = Provider.of<AuthProvider>(context);
    // final user = authProvider.user; // Bisa digunakan untuk sapaan, dll.

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    backgroundImage:
                        _currentUser?.id !=
                                null // Ganti dengan logika avatar yang benar
                            ? NetworkImage(
                              'https://ui-avatars.com/api/?name=${_currentUser!.name.replaceAll(' ', '+')}&background=random&size=128',
                            )
                            : null,
                    backgroundColor: Colors.grey[300],
                    child:
                        _currentUser?.id == null
                            ? const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo, ${_currentUser?.name ?? 'Tamu'}!",
                        style: AppTextStyles.heading.copyWith(fontSize: 18),
                      ),
                      Text(
                        "Siap nugas bareng hari ini?",
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: () async {
                      await Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      // Navigasi ke login akan dihandle oleh Consumer di main.dart
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),
              TextField(
                decoration: InputDecoration(
                  hintText: "Cari Grup...",
                  hintStyle: AppTextStyles.regular.copyWith(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  // Implementasi search (mungkin perlu debounce dan panggil API baru)
                },
              ),
              const SizedBox(height: 25),
              Text(
                "Temukan Grup",
                style: AppTextStyles.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Group>>(
                  future: _discoverableGroupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}",
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Belum ada grup tersedia."),
                      );
                    }
                    final groups = snapshot.data!;
                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadDiscoverableGroups();
                      },
                      child: ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return GroupCard(
                            group: group,
                            onJoinPressed: () {
                              _showJoinConfirmationDialog(context, group);
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
          _showCreateFullProjectDialog(context); // Panggil dialog baru
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: AppColors.background,
        ),
        label: const Text(
          "BUAT PROYEK BARU",
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_work_outlined),
            label: 'Grup Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey[500],
        onTap: _onItemTapped,
        backgroundColor: AppColors.background,
        elevation: 8.0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.regular.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.regular.copyWith(fontSize: 11),
      ),
    );
  }
}
