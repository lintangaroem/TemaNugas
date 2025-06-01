// lib/ui/widgets/group_card.dart
import 'package:flutter/material.dart';
import '../../../models/group.dart';
import '../../../constants/constant.dart'; // Sesuaikan path

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onJoinPressed;
  // Tambahkan callback lain jika perlu, misal onTap untuk lihat detail

  const GroupCard({
    super.key,
    required this.group,
    required this.onJoinPressed,
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
            Text(group.name, style: AppTextStyles.content.copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            if (group.description != null && group.description!.isNotEmpty) ...[
              Text(
                group.description!,
                style: AppTextStyles.regular.copyWith(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(
                  "Dibuat oleh: ${group.creator?.name ?? 'N/A'}",
                  style: AppTextStyles.regular.copyWith(color: Colors.grey[700], fontSize: 12)
                ),
                const Spacer(),
                 if (group.approvedMembersCount != null) ...[
                  Icon(Icons.group, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    "${group.approvedMembersCount} Anggota",
                    style: AppTextStyles.regular.copyWith(color: Colors.grey[700], fontSize: 12)
                  ),
                 ]
              ],
            ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onJoinPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  textStyle: AppTextStyles.regular.copyWith(fontWeight: FontWeight.w500, fontSize: 13)
                ),
                child: const Text("REQUEST JOIN"), // Atau status lain
              ),
            ),
          ],
        ),
      ),
    );
  }
}
