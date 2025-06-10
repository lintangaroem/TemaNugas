// lib/screens/home/dialogs/request_join_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TemaNugas/constants/constant.dart';
import 'package:TemaNugas/models/project.dart';
import 'package:TemaNugas/providers/auth_provider.dart';
import 'package:TemaNugas/services/api/api_services.dart';

Future<void> showRequestJoinConfirmationDialog(
  BuildContext context,
  Project project,
  ApiService apiService,
) async {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          project.name,
          style: AppTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            child: const Text("KIRIM PERMINTAAN"),
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Close dialog first
              try {
                await apiService.requestToJoinProject(project.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permintaan bergabung ke "${project.name}" terkirim!'),
                    backgroundColor: AppColors.greenSuccess,
                  ),
                );
                // Refresh user details to update their pending requests
                Provider.of<AuthProvider>(context, listen: false).fetchUserDetails();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal: ${e.toString().replaceFirst("Exception: ", "")}'),
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