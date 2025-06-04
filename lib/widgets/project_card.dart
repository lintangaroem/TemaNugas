import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project.dart'; 
import '../constants/constant.dart';
import '../screens/pages/group_detail_page.dart';
import '../screens/pages/projects_overview_page.dart';
import '../models/user/authenticated_user.dart';
import '../services/API/api_services.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onRequestJoinPressed; // Aksi ketika tombol "REQUEST JOIN" ditekan
  final VoidCallback? onTap; // Opsional: Aksi ketika kartu di-tap (misal untuk lihat detail)
  // Tambahkan field untuk status user terhadap proyek ini jika API menyediakannya
  final String? userProjectStatus; // misal: 'pending', 'approved', 'creator', null

  const ProjectCard({
    super.key,
    required this.project,
    required this.onRequestJoinPressed,
    this.onTap,
    this.userProjectStatus,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText = "REQUEST JOIN";
    bool canRequestJoin = true;

    if (userProjectStatus == 'pending') {
      buttonText = "REQUEST SENT";
      canRequestJoin = false;
    } else if (userProjectStatus == 'approved' || userProjectStatus == 'creator') {
      buttonText = "VIEW PROJECT";
      canRequestJoin = false; // Atau arahkan ke detail jika di-tap
    }

    return Card(
      // Menggunakan styling dari AppTheme.cardTheme secara default
      margin: const EdgeInsets.only(bottom: 18.0),
      child: InkWell(
        onTap: onTap ?? ( (userProjectStatus == 'approved' || userProjectStatus == 'creator') ? () {
          // Jika sudah jadi anggota atau creator, onTap bisa langsung ke detail
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)));
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigasi ke detail proyek: ${project.name}')),
          );
        } : null), // Hanya bisa di-tap jika sudah jadi anggota atau ada aksi spesifik
        borderRadius: BorderRadius.circular(12.0), // Sesuaikan dengan cardTheme
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                project.name,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 6),
              if (project.description != null && project.description!.isNotEmpty) ...[
                Text(
                  project.description!,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Dibuat oleh: ${project.creator?.name ?? 'N/A'}",
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Anda bisa menambahkan info jumlah anggota jika API menyediakannya di list project
                  // Icon(Icons.group_outlined, size: 16, color: AppColors.textLight),
                  // SizedBox(width: 4),
                  // Text("${project.membersCount ?? 0} Anggota", style: AppTextStyles.labelSmall),
                ],
              ),
              if (project.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(
                      "Deadline: ${DateFormat('dd MMMM yyyy', 'id_ID').format(project.deadline!)}", // Format tanggal Indonesia
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (canRequestJoin)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onRequestJoinPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(buttonText),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
