import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/widgets/project_card.dart';

import '../../constants/constant.dart';
import '../../constants/theme.dart';
import '../../models/project.dart';
import '../../models/user/authenticated_user.dart';
import '../../services/api/api_services.dart';
import '../../providers/auth_provider.dart';
import 'group_detail_page.dart';
import 'group_page.dart';
import 'projects_overview_page.dart'; 
import 'profile.dart';


// Konten untuk tab Beranda
class HomeContent extends StatefulWidget {
  final Function? onRefreshRequested;
  final Future<List<Project>>? projectsFuture; // Terima future dari parent
  final Function(BuildContext, Project) showRequestJoinDialog; // Callback untuk dialog
  final Function(Project) navigateToDetail; // Callback untuk navigasi

  const HomeContent({
    super.key,
    this.onRefreshRequested,
    this.projectsFuture,
    required this.showRequestJoinDialog,
    required this.navigateToDetail,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Logika search akan dipindahkan ke HomePageState agar bisa refresh FutureBuilder
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: widget.projectsFuture, // Gunakan future dari widget
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.redAlert)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                const SizedBox(height:10),
                Text("Belum ada proyek tersedia.", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)),
                const SizedBox(height:5),
                Text("Coba buat proyek baru atau refresh!", style: AppTextStyles.bodyMedium),
                 const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Refresh Proyek"),
                  onPressed: () {
                    widget.onRefreshRequested?.call();
                  },
                )
              ],
            )
          );
        }
        // Jika ada data, tampilkan _filteredProjects dari HomePageState
        // Untuk sementara, kita tampilkan semua data dari snapshot
        final projectsToDisplay = snapshot.data!;
        if (projectsToDisplay.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                const SizedBox(height:10),
                Text("Tidak ada proyek ditemukan.", style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)),
              ],
            )
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            widget.onRefreshRequested?.call();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: projectsToDisplay.length,
            itemBuilder: (context, index) {
              final project = projectsToDisplay[index];
              return ProjectCard(
                project: project,
                onRequestJoinPressed: () {
                  widget.showRequestJoinDialog(context, project);
                },
                onTap: () {
                  widget.navigateToDetail(project);
                },
              );
            },
          ),
        );
      },
    );
  }
}


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

  String _searchQuery = '';
  List<Project> _allProjects = [];
  List<Project> _filteredProjects = []; // Ini akan digunakan oleh HomeContent

  final _addProjectFormKey = GlobalKey<FormState>();
  final TextEditingController _newProjectNameController = TextEditingController();
  final TextEditingController _newProjectDescriptionController = TextEditingController();
  DateTime? _selectedDeadline;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _loadDiscoverableProjects(); // Memuat data awal
    Provider.of<AuthProvider>(context, listen: false).addListener(_updateCurrentUserAndRefreshProjects);

    _pages = [
      HomeContent(
        onRefreshRequested: _loadDiscoverableProjects, // Pass fungsi refresh
        projectsFuture: _discoverableProjectsFuture, // Pass future awal
        showRequestJoinDialog: _showRequestJoinConfirmationDialog,
        navigateToDetail: (project) {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
          ).then((_) => _loadDiscoverableProjects());
        },
      ),
      const GroupPage(),
      const ProfilePage(),
    ];
  }

  void _updateCurrentUserAndRefreshProjects() {
    if (mounted) {
      setState(() {
        _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
      });
      _loadDiscoverableProjects(); // Refresh proyek juga jika user data berubah (misal setelah join/leave project)
    }
  }

  @override
  void dispose() {
    Provider.of<AuthProvider>(context, listen: false).removeListener(_updateCurrentUserAndRefreshProjects);
    _newProjectNameController.dispose();
    _newProjectDescriptionController.dispose();
    super.dispose();
  }

  void _loadDiscoverableProjects() {
    final future = _apiService.getDiscoverableProjects();
    if (mounted) {
      setState(() {
        _discoverableProjectsFuture = future;
      });
    }
    future.then((projects) {
      if (mounted) {
        setState(() {
          _allProjects = projects;
          _filterProjects(); // Filter setelah mendapatkan semua proyek
           // Update _pages dengan future yang baru untuk HomeContent
          _pages[0] = HomeContent(
            onRefreshRequested: _loadDiscoverableProjects,
            projectsFuture: Future.value(_filteredProjects), // Berikan filtered projects
            showRequestJoinDialog: _showRequestJoinConfirmationDialog,
            navigateToDetail: (project) {
              Navigator.push(
                context, // Gunakan context dari _HomePageState
                MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
              ).then((_) {
                if (mounted) _loadDiscoverableProjects();
              });
            },
          );
        });
      }
    }).catchError((error) {
      if (mounted) { // Cek mounted sebelum menggunakan context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat proyek: ${error.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
        );
      }
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
    // Update HomeContent dengan data yang sudah difilter
    if (mounted) {
       setState(() {
        _pages[0] = HomeContent(
          onRefreshRequested: _loadDiscoverableProjects,
          projectsFuture: Future.value(_filteredProjects), // Berikan filtered projects
          showRequestJoinDialog: _showRequestJoinConfirmationDialog,
          navigateToDetail: (project) {
            Navigator.push(
              context, // Gunakan context dari _HomePageState
              MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
            ).then((_) {
              if (mounted) _loadDiscoverableProjects();
            });
          },
        );
      });
    }
  }

  void _onItemTapped(int index) {
    // ... (logika navigasi Anda yang sudah ada, pastikan context valid jika ada async)
    if (_selectedIndex == index && index != 0) return;

    if (index == 0 && _selectedIndex !=0) {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (ctx) => const HomePage()), // Gunakan ctx dari builder jika ada
        (Route<dynamic> route) => false,
      );
      // Tidak perlu setState karena halaman di-replace
      return; 
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const GroupPage()),
      );
       return;
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const ProfilePage()),
      );
       return;
    }
    // Untuk kasus di mana halaman tidak di-replace dan _selectedIndex perlu diupdate
    // Ini mungkin tidak akan pernah tercapai jika semua navigasi adalah pushReplacement
    if (mounted) {
        setState(() {
            _selectedIndex = index;
        });
    }
  }

  Widget _buildDialogTextField(TextEditingController controller, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
      ),
      validator: validator,
    );
  }

  void _showCreateProjectDialog() { // Hapus BuildContext parameter jika tidak digunakan langsung
    _newProjectNameController.clear();
    _newProjectDescriptionController.clear();
    _selectedDeadline = null;

    // Simpan context dari _HomePageState sebelum async gap
    final pageContext = context; 

    showDialog(
      context: pageContext, // Gunakan pageContext
      builder: (dialogContext) { 
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return AlertDialog(
              title: const Center(child: Text('Buat Proyek Baru')),
              content: Form(
                key: _addProjectFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogTextField(
                        _newProjectNameController,
                        'Nama Proyek*',
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama proyek tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      Text("Deadline Proyek (Opsional)", style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: stfContext,
                            initialDate: _selectedDeadline ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime(2101),
                            helpText: 'PILIH TANGGAL DEADLINE',
                             builder: (pickerContext, child) => Theme(
                                data: AppTheme.lightTheme.copyWith(
                                  colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
                                    primary: AppColors.primaryBlue, onPrimary: Colors.white,
                                    surface: AppColors.background, onSurface: AppColors.textDark,
                                  ),
                                  dialogBackgroundColor: AppColors.background,
                                ),
                                child: child!,
                              ),
                          );
                          if (picked != null && picked != _selectedDeadline) {
                            setDialogState(() => _selectedDeadline = picked);
                          }
                        },
                        child: Container( /* ... UI Date Picker ... */ 
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDeadline == null ? 'Pilih Tanggal' : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDeadline!),
                                style: _selectedDeadline == null ? AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]) : AppTextStyles.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(_newProjectDescriptionController, 'Deskripsi (Opsional)', maxLines: 3),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.end,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('BATAL')),
                ElevatedButton(
                  onPressed: () async {
                    if (_addProjectFormKey.currentState!.validate()) {
                      _addProjectFormKey.currentState!.save();

                      final String projectName = _newProjectNameController.text.trim();
                      final String? projectDescription = _newProjectDescriptionController.text.trim().isEmpty
                          ? null : _newProjectDescriptionController.text.trim();
                      final DateTime? deadline = _selectedDeadline;

                      // Tampilkan loading indicator
                      // Simpan dialogContext untuk menutup loading dialog
                      final currentDialogContext = dialogContext; 
                      showDialog(
                        context: currentDialogContext, // Gunakan context yang tepat
                        barrierDismissible: false,
                        builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final newProject = await _apiService.createProject(projectName, projectDescription, deadline);

                        if (!pageContext.mounted) return; // Cek mounted untuk pageContext
                        Navigator.of(currentDialogContext).pop(); // Tutup loading indicator
                        Navigator.of(pageContext).pop(); // Tutup dialog utama menggunakan pageContext (atau dialogContext jika masih valid)

                        ScaffoldMessenger.of(pageContext).showSnackBar(
                          SnackBar(content: Text('Proyek "${newProject.name}" berhasil dibuat!'), backgroundColor: AppColors.greenSuccess),
                        );
                        _loadDiscoverableProjects(); 
                        Provider.of<AuthProvider>(pageContext, listen: false).fetchUserDetails();

                      } catch (e) {
                        if (!pageContext.mounted) return;
                        Navigator.of(currentDialogContext).pop(); // Tutup loading indicator
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                          SnackBar(content: Text('Gagal membuat proyek: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.redAlert),
                        );
                      }
                    }
                  },
                  child: const Text('BUAT PROYEK'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showRequestJoinConfirmationDialog(BuildContext context, Project project) { // context di sini adalah dari item builder
    final pageContext = this.context; // context dari _HomePageState

    showDialog(
      context: context, // context dari item builder, yang seharusnya masih valid
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(project.name, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
          content: Column( /* ... UI Konten Dialog ... */
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(project.description ?? "Tidak ada deskripsi.", style: AppTextStyles.bodyMedium, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              const Text("Anda akan mengirim permintaan untuk bergabung dengan proyek ini. Lanjutkan?", style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("BATAL")),
            ElevatedButton(
              child: const Text("KIRIM PERMINTAAN"),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Tutup dialog konfirmasi
                try {
                  await _apiService.requestToJoinProject(project.id);
                  if (!pageContext.mounted) return; // Cek mounted untuk pageContext
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Permintaan bergabung ke "${project.name}" terkirim!'), backgroundColor: AppColors.greenSuccess),
                  );
                  Provider.of<AuthProvider>(pageContext, listen: false).fetchUserDetails();
                } catch (e) {
                  if (!pageContext.mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
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
    final authProvider = Provider.of<AuthProvider>(context);
    final username = authProvider.user?.name ?? "Pengguna";

    // Update _pages setiap kali build dipanggil dengan _discoverableProjectsFuture yang baru
    // atau lebih baik, HomeContent menggunakan _filteredProjects secara langsung.
    // Untuk sementara, kita update _pages di sini juga jika _discoverableProjectsFuture berubah.
    // Ini akan memastikan HomeContent mendapatkan future yang benar.
    _pages[0] = HomeContent(
      onRefreshRequested: _loadDiscoverableProjects,
      projectsFuture: _discoverableProjectsFuture, // Ini akan berisi _filteredProjects setelah _filterProjects
      showRequestJoinDialog: _showRequestJoinConfirmationDialog,
      navigateToDetail: (project) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
        ).then((_) {
          if (mounted) _loadDiscoverableProjects();
        });
      },
    );


    return Scaffold(
      body: SafeArea( /* ... UI Anda yang sudah ada ... */
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Row(children: [ /* ... UI Header ... */ 
                CircleAvatar(
                  radius: 28, backgroundColor: AppColors.lightGrey,
                  backgroundImage: _currentUser?.name != null ? NetworkImage('https://ui-avatars.com/api/?name=${_currentUser!.name.replaceAll(' ', '+')}&background=random&color=fff&size=128') : null,
                  child: _currentUser?.name == null ? const Icon(Icons.person, size: 28, color: AppColors.textLight) : null,
                ),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Halo, $username!", style: AppTextStyles.titleLarge, overflow: TextOverflow.ellipsis),
                  Text("Siap nugas bareng hari ini?", style: AppTextStyles.bodyMedium),
                ])),
                IconButton(icon: const Icon(Icons.logout_outlined, color: AppColors.primaryBlue), tooltip: "Logout",
                  onPressed: () async {
                    if (!mounted) return; // Cek mounted sebelum async
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                  })
              ]),
              const SizedBox(height: 25),
              TextField(
                decoration: const InputDecoration(hintText: "Cari Proyek...", prefixIcon: Icon(Icons.search_rounded)),
                onChanged: (value) {
                  if (mounted) { // Cek mounted sebelum setState
                    setState(() {
                      _searchQuery = value;
                      _filterProjects();
                    });
                  }
                },
              ),
              const SizedBox(height: 25),
              Text("Temukan Proyek", style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: 10),
              Expanded(child: _pages[0]), // Langsung tampilkan HomeContent dari _pages
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(), // Tidak perlu pass context
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
