import 'package:flutter/material.dart';
import 'package:TemaNugas/constants/constant.dart';
import 'package:TemaNugas/models/project.dart';
import 'package:TemaNugas/widgets/project_card.dart';

class HomeContent extends StatelessWidget {
  final List<Project> projects;
  final Future<void> Function() onRefresh;
  final Function(Project) onRequestJoin;
  final Function(Project) onNavigateToDetail;

  const HomeContent({
    super.key,
    required this.projects,
    required this.onRefresh,
    required this.onRequestJoin,
    required this.onNavigateToDetail,
  });

  @override
  Widget build(BuildContext context) {
    // Logika jika tidak ada proyek (baik karena filter atau memang kosong)
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              "Proyek tidak ditemukan.",
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 5),
            Text("Coba kata kunci lain atau buat proyek baru!", style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Refresh Halaman"),
              onPressed: onRefresh,
            ),
          ],
        ),
      );
    }

    // Tampilkan daftar proyek jika ada
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ProjectCard(
            project: project,
            onRequestJoinPressed: () => onRequestJoin(project),
            onTap: () => onNavigateToDetail(project),
          );
        },
      ),
    );
  }
}