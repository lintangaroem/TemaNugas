// lib/screens/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/constants/constant.dart';
import 'package:TemaNugas/models/project.dart';
import 'package:TemaNugas/providers/auth_provider.dart';
import 'package:TemaNugas/services/api/api_services.dart';
import 'package:TemaNugas/widgets/navbar.dart';
import 'package:TemaNugas/screens/pages/group_detail_page.dart';
import 'package:TemaNugas/screens/pages/group_page.dart';
import 'package:TemaNugas/screens/pages/profile.dart';
import 'dialog/create_project_dialog.dart';
import 'dialog/request_join_dialog.dart';
import 'widget/home_content.dart';
import 'widget/home_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<Project>> _projectsFuture;

  String _searchQuery = '';
  List<Project> _allProjects = []; // Tetap simpan semua project untuk filtering

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadDiscoverableProjects();
    Provider.of<AuthProvider>(context, listen: false).addListener(_onAuthChange);
  }

  @override
  void dispose() {
    Provider.of<AuthProvider>(context, listen: false).removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    // Jika ada perubahan user, panggil _refreshProjects
    _refreshProjects();
  }

  Future<List<Project>> _loadDiscoverableProjects() async {
    final projects = await _apiService.getDiscoverableProjects();
    if (mounted) {
      // Simpan data asli ke _allProjects
      _allProjects = projects;
    }
    return projects;
  }

  void _refreshProjects() {
    if (mounted) {
      setState(() {
        _projectsFuture = _loadDiscoverableProjects();
      });
    }
  }

  List<Project> _getFilteredProjects() {
    if (_searchQuery.isEmpty) {
      return _allProjects;
    }
    return _allProjects
        .where((project) =>
            project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (project.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
        .toList();
  }

  void _onSearchChanged(String query) {
    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
        // Tidak perlu panggil API, cukup re-render dengan filter baru
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) return;
    Widget page;
    switch (index) {
      case 1: page = const GroupPage(); break;
      case 2: page = const ProfilePage(); break;
      default: return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  void _navigateToDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
    ).then((_) => _refreshProjects());
  }

  void _showCreateProjectDialog() async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateProjectDialog(apiService: _apiService),
    );

    if (result == null || !mounted) return;

    if (result is Project) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Proyek "${result.name}" berhasil dibuat!'),
        backgroundColor: AppColors.greenSuccess,
      ));
      await Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
    } else if (result is Exception) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal membuat proyek: ${result.toString().replaceFirst("Exception: ", "")}'),
        backgroundColor: AppColors.redAlert,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              HomeHeader(currentUser: currentUser),
              const SizedBox(height: 25),
              TextField(
                decoration: const InputDecoration(
                  hintText: "Cari Proyek...",
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 25),
              Text(
                "Temukan Proyek",
                style: AppTextStyles.heading.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Expanded(
                // KEMBALIKAN FUTUREBUILDER DI SINI!
                child: FutureBuilder<List<Project>>(
                  future: _projectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Text(
                              "Gagal memuat proyek",
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.redAlert),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text("Coba Lagi"),
                              onPressed: _refreshProjects,
                            )
                          ],
                        ),
                      );
                    }
                    
                    // Jika berhasil, filter datanya
                    final filteredProjects = _getFilteredProjects();

                    return HomeContent(
                      projects: filteredProjects,
                      onRefresh: () async => _refreshProjects(),
                      onRequestJoin: (project) => showRequestJoinConfirmationDialog(context, project, _apiService),
                      onNavigateToDetail: _navigateToDetail,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text("BUAT PROYEK"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onItemTapped,
      ),
    );
  }
}