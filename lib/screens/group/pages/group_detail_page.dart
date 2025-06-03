// lib/ui/screens/group_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

import '../../../constants/constant.dart';
import '../../../models/group.dart';
import '../../../models/project.dart';
import '../../../models/user/user.dart';
import '../../../models/user/authenticated_user.dart';
import '../../../services/API/api_services.dart';
import '../../../providers/auth_provider.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ApiService _apiService = ApiService();
  Future<Group>? _groupDetailsFuture;
  Future<List<Project>>? _projectsFuture;
  Future<List<User>>? _joinRequestsFuture; // Hanya untuk group creator

  AuthenticatedUser? _currentUser;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _loadGroupData();
  }

  void _loadGroupData() {
    setState(() {
      _groupDetailsFuture = _apiService.getGroupDetails(widget.groupId);
      _projectsFuture = _apiService.getProjectsForGroup(widget.groupId);

      // Cek apakah user saat ini adalah pembuat grup setelah detail grup dimuat
      _groupDetailsFuture!.then((group) {
        if (mounted) {
          setState(() {
            _isCreator = group.createdBy == _currentUser?.id;
            if (_isCreator) {
              _joinRequestsFuture = _apiService.listJoinRequests(widget.groupId);
            }
          });
        }
      }).catchError((error) {
        // Handle error jika getGroupDetails gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat detail grup: $error'), backgroundColor: AppColors.redAlert),
          );
        }
      });
    });
  }

  void _refreshAllData() {
    // Panggil _loadGroupData untuk memuat ulang semua data terkait grup
    _loadGroupData();
    // Juga refresh data user di AuthProvider jika ada perubahan keanggotaan
    Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
  }


  // --- DIALOG TAMBAH PROYEK ---
  void _showAddProjectDialog(BuildContext context, int groupId) {
    final formKey = GlobalKey<FormState>();
    String projectName = '';
    String projectDescription = '';
    DateTime? projectDeadline;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Gunakan StatefulBuilder agar bisa update state di dalam dialog (untuk tanggal)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Tambah Proyek Baru", style: AppTextStyles.heading),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Nama Proyek",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Nama proyek tidak boleh kosong';
                          return null;
                        },
                        onSaved: (value) => projectName = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Deskripsi Proyek (Opsional)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 3,
                        onSaved: (value) => projectDescription = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      Text("Deadline Proyek (Opsional)", style: AppTextStyles.regular.copyWith(fontSize: 14)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: projectDeadline ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != projectDeadline) {
                            setDialogState(() { // Update state di dalam dialog
                              projectDeadline = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                projectDeadline == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMMM yyyy').format(projectDeadline!),
                                style: AppTextStyles.regular.copyWith(fontSize: 15),
                              ),
                              const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
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
                  child: const Text("BATAL", style: TextStyle(color: AppColors.redAlert)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text("TAMBAH PROYEK"),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      try {
                        final newProject = await _apiService.createProject(
                          groupId,
                          projectName,
                          projectDescription,
                          projectDeadline,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Proyek "${newProject.name}" berhasil ditambah!'), backgroundColor: Colors.green),
                        );
                        _refreshAllData(); // Refresh daftar proyek
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menambah proyek: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- UI PERSETUJUAN ANGGOTA ---
  Widget _buildJoinRequestsSection() {
    if (!_isCreator || _joinRequestsFuture == null) {
      return const SizedBox.shrink(); // Jangan tampilkan jika bukan creator atau future null
    }

    return FutureBuilder<List<User>>(
      future: _joinRequestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isCreator) { // Hanya tampilkan loading jika memang ada yg di-load
          return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.all(16.0), child: Text("Error memuat permintaan: ${snapshot.error}", style: const TextStyle(color: AppColors.redAlert)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(padding: EdgeInsets.symmetric(vertical:10.0), child: Text("Tidak ada permintaan bergabung saat ini.", style: AppTextStyles.regular));
        }

        final requests = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text("Permintaan Bergabung (${requests.length})", style: AppTextStyles.content.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final userRequesting = requests[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Text(userRequesting.name.substring(0,1).toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(userRequesting.name, style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Text(userRequesting.email, style: AppTextStyles.regular.copyWith(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          tooltip: "Setujui",
                          onPressed: () async {
                            try {
                              String message = await _apiService.approveJoinRequest(widget.groupId, userRequesting.id);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
                              _refreshAllData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.redAlert));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.highlight_off_outlined, color: AppColors.redAlert),
                          tooltip: "Tolak",
                          onPressed: () async {
                             try {
                              String message = await _apiService.rejectJoinRequest(widget.groupId, userRequesting.id);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.orange));
                              _refreshAllData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.redAlert));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
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
      appBar: AppBar(
        title: FutureBuilder<Group>(
          future: _groupDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Memuat...", style: AppTextStyles.heading);
            } else if (snapshot.hasData) {
              return Text(snapshot.data!.name, style: AppTextStyles.heading);
            }
            return const Text("Detail Grup", style: AppTextStyles.heading);
          },
        ),
        backgroundColor: AppColors.background,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAllData();
        },
        child: FutureBuilder<Group>(
          future: _groupDetailsFuture,
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (groupSnapshot.hasError) {
              return Center(child: Text("Error memuat grup: ${groupSnapshot.error}"));
            }
            if (!groupSnapshot.hasData) {
              return const Center(child: Text("Grup tidak ditemukan."));
            }

            final group = groupSnapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Informasi Grup
                Text(group.name, style: AppTextStyles.heading.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                if (group.description != null && group.description!.isNotEmpty)
                  Text(group.description!, style: AppTextStyles.regular.copyWith(fontSize: 15, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_pin_circle_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text("Dibuat oleh: ${group.creator?.name ?? 'N/A'}", style: AppTextStyles.regular),
                  ],
                ),
                if (group.createdAt != null) ... [
                  const SizedBox(height: 4),
                   Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text("Dibuat pada: ${DateFormat('dd MMMM yyyy').format(group.createdAt!)}", style: AppTextStyles.regular.copyWith(fontSize: 12)),
                    ],
                  ),
                ],
                const Divider(height: 30),

                // Bagian Permintaan Bergabung (hanya untuk creator)
                _buildJoinRequestsSection(),

                // Daftar Proyek
                Text("Proyek dalam Grup Ini", style: AppTextStyles.content.copyWith(fontSize: 17)),
                const SizedBox(height: 10),
                FutureBuilder<List<Project>>(
                  future: _projectsFuture,
                  builder: (context, projectSnapshot) {
                    if (projectSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (projectSnapshot.hasError) {
                      return Text("Error memuat proyek: ${projectSnapshot.error}", style: const TextStyle(color: AppColors.redAlert));
                    }
                    if (!projectSnapshot.hasData || projectSnapshot.data!.isEmpty) {
                      return const Text("Belum ada proyek dalam grup ini.", style: AppTextStyles.regular);
                    }
                    final projects = projectSnapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                                child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue)
                            ),
                            title: Text(project.name, style: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              "Deadline: ${project.deadline != null ? DateFormat('dd MMM yyyy').format(project.deadline!) : 'N/A'} - Status: ${project.status}",
                              style: AppTextStyles.regular.copyWith(fontSize: 12)
                            ),
                            onTap: () {
                              // Navigasi ke halaman detail proyek
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Halaman Detail Proyek "${project.name}" belum dibuat.')),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _isCreator // Hanya tampilkan FAB jika user adalah pembuat grup
          ? FloatingActionButton.extended(
              onPressed: () {
                _showAddProjectDialog(context, widget.groupId);
              },
              icon: const Icon(Icons.add_task_outlined),
              label: const Text("TAMBAH PROYEK"),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.background,
            )
          : null,
    );
  }
}
