import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Sesuaikan path import ini dengan struktur proyek Anda
import '../../../providers/auth_provider.dart';
import '../../../services/API/api_services.dart'; // Menggunakan nama file dari kode Anda
import '../../../models/project.dart';
import 'package:TemaNugas/models/user/authenticated_user.dart';
import 'package:TemaNugas/models/user/user.dart';
import '../../../models/todo.dart';
// import '../../../models/note.dart'; // Untuk fitur Notes nanti
import '../../../constants/constant.dart';
import '../../../constants/theme.dart';
import 'todo/todo_item_tile.dart'; // Widget TodoItemTile yang baru dibuat

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Future<Project>? _projectDetailsFuture;
  
  // Menggunakan List untuk menyimpan data yang bisa di-refresh
  List<User> _joinRequests = [];
  List<Todo> _todos = [];
  List<User> _approvedMembers = [];

  AuthenticatedUser? _currentUser;
  bool _isCreator = false;
  bool _isApprovedMember = false;
  bool _hasPendingRequest = false; // Apakah user saat ini punya request pending ke proyek ini
  bool _isLoadingProject = true; // Untuk loading awal detail proyek
  bool _isLoadingTodos = false;
  bool _isLoadingJoinRequests = false;

  final TextEditingController _newTodoController = TextEditingController();
  final TextEditingController _editTodoController = TextEditingController(); // Untuk edit judul todo

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 0: Tugas, 1: Anggota, 2: Catatan (atau Permintaan jika creator)
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _loadAllProjectData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _newTodoController.dispose();
    _editTodoController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProjectData({bool showFullLoading = true}) async {
    if (showFullLoading && mounted) {
      setState(() {
        _isLoadingProject = true;
      });
    }

    try {
      final project = await _apiService.getProjectDetails(widget.projectId);
      if (!mounted) return;

      setState(() {
        _isCreator = project.isCreator(_currentUser?.id);
        _approvedMembers = project.approvedMembers ?? [];
        _isApprovedMember = _approvedMembers.any((member) => member.id == _currentUser?.id) || _isCreator;
        _hasPendingRequest = _currentUser?.pendingProjectRequests.any((p) => p.id == project.id) ?? false;
        _projectDetailsFuture = Future.value(project); // Update future dengan data yang sudah ada

        if (_isCreator || _isApprovedMember) {
          _loadTodos();
        }
        if (_isCreator) {
          _loadJoinRequests();
        }
        _isLoadingProject = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingProject = false;
          // Set _projectDetailsFuture ke error agar FutureBuilder bisa menampilkannya
          _projectDetailsFuture = Future.error(error);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail proyek: ${error.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
        );
      }
    }
  }
  
  Future<void> _loadTodos() async {
    if (mounted) setState(() => _isLoadingTodos = true);
    try {
      final todos = await _apiService.getTodosForProject(widget.projectId);
      if (mounted) setState(() => _todos = todos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat tugas: $e'), backgroundColor: AppColors.redAlert));
      }
    } finally {
      if (mounted) setState(() => _isLoadingTodos = false);
    }
  }

  Future<void> _loadJoinRequests() async {
    if (!_isCreator) return;
    if (mounted) setState(() => _isLoadingJoinRequests = true);
    try {
      final requests = await _apiService.listProjectJoinRequests(widget.projectId);
      if (mounted) setState(() => _joinRequests = requests);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat permintaan bergabung: $e'), backgroundColor: AppColors.redAlert));
      }
    } finally {
      if (mounted) setState(() => _isLoadingJoinRequests = false);
    }
  }


  Future<void> _refreshData() async {
    await _loadAllProjectData(showFullLoading: false);
    // Refresh juga data user di AuthProvider jika ada perubahan keanggotaan
    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
    }
  }

  // --- DIALOG TAMBAH TODO ---
  void _showAddEditTodoDialog({Todo? existingTodo}) {
    _editTodoController.text = existingTodo?.title ?? '';
    final formKey = GlobalKey<FormState>();
    bool isEditing = existingTodo != null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? "Edit Tugas" : "Tambah Tugas Baru"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: _editTodoController,
              decoration: const InputDecoration(labelText: "Nama Tugas*"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Nama tugas tidak boleh kosong';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Batal")),
            ElevatedButton(
              child: Text(isEditing ? "Simpan" : "Tambah"),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final title = _editTodoController.text.trim();
                  Navigator.of(dialogContext).pop(); // Tutup dialog dulu
                  try {
                    if (isEditing) {
                      await _apiService.updateTodo(widget.projectId, existingTodo!.id, title, existingTodo.isCompleted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tugas "${existingTodo.title}" berhasil diperbarui.'), backgroundColor: AppColors.greenSuccess),
                      );
                    } else {
                      await _apiService.createTodo(widget.projectId, title);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tugas "$title" berhasil ditambah.'), backgroundColor: AppColors.greenSuccess),
                      );
                    }
                    _loadTodos(); // Refresh daftar todo
                  } catch (e) {
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
  }

  // --- UI SECTIONS ---
  Widget _buildMyTaskListSectionWidget() {
    if (!_isCreator && !_isApprovedMember) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text("Anda harus menjadi anggota untuk melihat daftar tugas.", style: AppTextStyles.bodyMedium)),
      );
    }
    if (_isLoadingTodos) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_todos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text("Belum ada tugas dalam proyek ini.", style: AppTextStyles.bodyMedium)),
      );
    }
    return ListView.builder(
      // physics: const NeverScrollableScrollPhysics(), // Dihilangkan agar bisa scroll jika konten tab panjang
      // shrinkWrap: true, // Dihilangkan
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        bool canModifyTodo = (_currentUser?.id == todo.createdByUserId) || _isCreator;
        return TodoItemTile(
          todo: todo,
          canModify: _isCreator || _isApprovedMember, // Semua anggota bisa update status, creator/pembuat bisa hapus/edit
          onTap: canModifyTodo ? () => _showAddEditTodoDialog(existingTodo: todo) : null,
          onStatusChanged: (bool? newValue) async {
            if (newValue != null) {
              final originalStatus = todo.isCompleted;
              setState(() => todo.isCompleted = newValue); // Optimistic update
              try {
                await _apiService.updateTodo(widget.projectId, todo.id, todo.title, newValue);
              } catch (e) {
                setState(() => todo.isCompleted = originalStatus); // Rollback
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update tugas: $e'), backgroundColor: AppColors.redAlert));
              }
            }
          },
          onDeletePressed: canModifyTodo ? () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Hapus Tugas?"), content: Text("Anda yakin ingin menghapus \"${todo.title}\"?"),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal")),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Hapus", style: TextStyle(color: AppColors.redAlert))),
                ],
              ));
            if (confirm == true) {
              try {
                await _apiService.deleteTodo(widget.projectId, todo.id);
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tugas "${todo.title}" dihapus.'), backgroundColor: AppColors.greenSuccess));
                _loadTodos();
              } catch (e) {
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus tugas: $e'), backgroundColor: AppColors.redAlert));
              }
            }
          } : null,
        );
      },
    );
  }

  Widget _buildMembersSectionWidget(Project project) {
    if (_isLoadingProject && _approvedMembers.isEmpty) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_approvedMembers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text("Belum ada anggota.", style: AppTextStyles.bodyMedium)),
      );
    }
    return ListView.builder(
      itemCount: _approvedMembers.length,
      itemBuilder: (context, index) {
        final member = _approvedMembers[index];
        bool isProjectCreator = project.createdBy == member.id;
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.lightGrey,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${member.name.replaceAll(' ', '+')}&background=random&color=fff&size=128'),
            ),
            title: Text(member.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
            subtitle: Text(member.email, style: AppTextStyles.labelSmall),
            trailing: isProjectCreator ? const Chip(avatar: Icon(Icons.star_rounded, color: AppColors.orangeWarning, size: 16), label: Text('Creator', style: AppTextStyles.labelSmall), padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0), visualDensity: VisualDensity.compact) : null,
          ),
        );
      },
    );
  }

  Widget _buildJoinRequestsSectionWidget() {
    if (!_isCreator) return const SizedBox.shrink(); // Hanya tampilkan jika creator
    if (_isLoadingJoinRequests) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_joinRequests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text("Tidak ada permintaan bergabung saat ini.", style: AppTextStyles.bodyMedium)),
      );
    }
    return ListView.builder(
      itemCount: _joinRequests.length,
      itemBuilder: (context, index) {
        final userRequesting = _joinRequests[index];
        return Card(
          elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Text(userRequesting.name.isNotEmpty ? userRequesting.name.substring(0,1).toUpperCase() : "?", style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ),
            title: Text(userRequesting.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
            subtitle: Text(userRequesting.email, style: AppTextStyles.labelSmall),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.check_circle_outline, color: AppColors.greenSuccess), tooltip: "Setujui",
                onPressed: () async {
                  try {
                    String message = await _apiService.approveProjectJoinRequest(widget.projectId, userRequesting.id);
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.greenSuccess));
                    _loadAllProjectData(showFullLoading: false); // Refresh semua data
                    Provider.of<AuthProvider>(context, listen: false).fetchUserDetails(); // Refresh data user juga
                  } catch (e) {
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.redAlert));
                  }
                }),
              IconButton(icon: const Icon(Icons.highlight_off_outlined, color: AppColors.redAlert), tooltip: "Tolak",
                onPressed: () async {
                  try {
                    String message = await _apiService.rejectProjectJoinRequest(widget.projectId, userRequesting.id);
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.orangeWarning));
                    _loadAllProjectData(showFullLoading: false);
                    Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
                  } catch (e) {
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.redAlert));
                  }
                }),
            ]),
          ));
      },
    );
  }

  // --- WIDGET UTAMA ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Project>(
      future: _projectDetailsFuture,
      builder: (context, projectSnapshot) {
        if (_isLoadingProject || !projectSnapshot.hasData && projectSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(title: const Text("Memuat Proyek...")), body: const Center(child: CircularProgressIndicator()));
        }
        if (projectSnapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text("Error")), body: Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Error memuat detail proyek: ${projectSnapshot.error.toString().replaceFirst("Exception: ", "")}", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.redAlert)),
          )));
        }
        if (!projectSnapshot.hasData) {
          return Scaffold(appBar: AppBar(title: const Text("Tidak Ditemukan")), body: const Center(child: Text("Proyek tidak ditemukan.", style: AppTextStyles.bodyLarge)));
        }

        final project = projectSnapshot.data!;
        // Update tab controller length based on whether user is creator for join requests tab
        final tabLength = _isCreator ? 4 : 3; // Detail, Tugas, Anggota, (Permintaan)
        if(_tabController?.length != tabLength) {
          _tabController = TabController(length: tabLength, vsync: this, initialIndex: _tabController?.index ?? 0);
        }


        return Scaffold(
          appBar: AppBar(
            title: Text(project.name, overflow: TextOverflow.ellipsis),
            bottom: TabBar(
              controller: _tabController,
              labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.bodyMedium,
              indicatorColor: AppColors.primaryBlue,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textLight,
              tabs: [
                const Tab(text: "Detail"),
                const Tab(text: "Tugas"),
                const Tab(text: "Anggota"),
                if (_isCreator) const Tab(text: "Permintaan"), // Tab Permintaan hanya untuk creator
              ],
            ),
            actions: [ // Tombol aksi di AppBar
              if (!_isCreator && !_isApprovedMember && !_hasPendingRequest)
                TextButton(
                  onPressed: () async {
                     try {
                        await _apiService.requestToJoinProject(project.id);
                        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permintaan bergabung terkirim!"), backgroundColor: AppColors.greenSuccess));
                        Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
                        _loadAllProjectData(showFullLoading: false);
                      } catch (e) {
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: AppColors.redAlert));
                      }
                  },
                  child: const Text("JOIN"),
                ),
              if (_isApprovedMember && !_isCreator)
                IconButton(
                  icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.redAlert),
                  tooltip: "Keluar Proyek",
                  onPressed: () async {
                     final confirmLeave = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text("Keluar Proyek?"), content: Text("Anda yakin ingin keluar dari proyek \"${project.name}\"?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal")),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Keluar", style: TextStyle(color: AppColors.redAlert))),
                        ]));
                      if (confirmLeave == true) {
                        try {
                          await _apiService.leaveProject(project.id); // Panggil API leave project
                          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anda telah keluar dari proyek."), backgroundColor: AppColors.orangeWarning));
                          Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
                          Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                        } catch (e) {
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal keluar: $e"), backgroundColor: AppColors.redAlert));
                        }
                      }
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Detail Proyek
                _buildProjectDetailsTab(project),
                // Tab 2: My Task List (Todos)
                _buildMyTaskListSectionWidget(),
                // Tab 3: Anggota
                _buildMembersSectionWidget(project),
                // Tab 4: Permintaan Bergabung (hanya untuk creator)
                if (_isCreator) _buildJoinRequestsSectionWidget(),
              ],
            ),
          ),
          floatingActionButton: (_isCreator || _isApprovedMember) && _tabController?.index == 1 // Hanya tampilkan FAB jika di tab Tugas dan user adalah anggota/creator
              ? FloatingActionButton(
                  onPressed: _showAddEditTodoDialog, // Menggunakan _showAddEditTodoDialog tanpa argumen untuk tambah baru
                  tooltip: 'Tambah Tugas',
                  child: const Icon(Icons.add_task),
                )
              : null,
        );
      },
    );
  }

  Widget _buildProjectDetailsTab(Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          if (project.description != null && project.description!.isNotEmpty) ...[
            Text("Deskripsi:", style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(project.description!, style: AppTextStyles.bodyLarge.copyWith(height: 1.5)),
            const SizedBox(height: 16),
          ],
          Row(children: [
            const Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.textLight),
            const SizedBox(width: 8),
            Text("Dibuat oleh: ", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text(project.creator?.name ?? 'N/A', style: AppTextStyles.bodyMedium),
          ]),
          const SizedBox(height: 8),
          if (project.deadline != null)
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Text("Deadline: ", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(DateFormat('dd MMMM yyyy', 'id_ID').format(project.deadline!), style: AppTextStyles.bodyMedium),
            ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textLight),
            const SizedBox(width: 8),
            Text("Status: ", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Chip(
              label: Text(project.status.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: project.status == 'completed' ? AppColors.greenSuccess : (project.status == 'in_progress' ? AppColors.primaryBlue : AppColors.orangeWarning),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              visualDensity: VisualDensity.compact,
            )
          ]),
          if (project.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.history_toggle_off_rounded, size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Text("Dibuat: ", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(project.createdAt!), style: AppTextStyles.labelSmall),
            ]),
          ],
           if (_hasPendingRequest) // Tampilkan status request jika ada
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Chip(
                avatar: Icon(Icons.hourglass_empty_rounded, color: AppColors.orangeWarning, size: 18),
                label: Text("Permintaan Bergabung Anda Sedang Diproses", style: AppTextStyles.bodyMedium),
                backgroundColor: AppColors.orangeWarning.withOpacity(0.1),
              )
            ),
        ],
      ),
    );
  }
}
