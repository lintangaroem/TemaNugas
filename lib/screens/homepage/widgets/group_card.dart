import 'package:flutter/material.dart';
import '../../../models/group.dart'; // Sesuaikan path jika model Group Anda ada di tempat lain
import 'package:teman_nugas/constants/constant.dart';    // Sesuaikan path jika constant.dart Anda ada di tempat lain

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onJoinPressed; // Aksi ketika tombol "REQUEST JOIN" ditekan
  final VoidCallback? onTap; // Opsional: Aksi ketika kartu di-tap (misal untuk lihat detail)

  const GroupCard({
    super.key,
    required this.group,
    required this.onJoinPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText = "REQUEST JOIN";
    // Anda bisa menambahkan logika di sini untuk mengubah teks tombol jika
    // Anda memiliki informasi status user terhadap grup ini (misal, "PENDING", "JOINED")
    // Contoh:
    // if (group.userStatusInGroup == 'pending') {
    //   buttonText = "REQUEST SENT";
    // } else if (group.userStatusInGroup == 'approved') {
    //   buttonText = "VIEW GROUP";
    // }

    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.only(bottom: 18.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // side: BorderSide(color: Colors.grey[300]!, width: 0.5), // Opsional border
      ),
      color: AppColors.background,
      child: InkWell( // Membuat seluruh kartu bisa di-tap jika onTap disediakan
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                group.name, // Kita sudah handle null di model atau akan pastikan tidak null dari API
                style: AppTextStyles.content.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (group.description != null && group.description!.isNotEmpty) ...[
                Text(
                  group.description!,
                  style: AppTextStyles.regular.copyWith(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Expanded( // Expanded agar teks tidak overflow jika nama creator panjang
                    child: Text(
                      "Dibuat oleh: ${group.creator?.name ?? 'N/A'}",
                      style: AppTextStyles.regular.copyWith(color: Colors.grey[700], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10), // Memberi jarak sebelum jumlah anggota
                  if (group.approvedMembersCount != null && group.approvedMembersCount! > 0) ...[
                    Icon(Icons.group_outlined, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      "${group.approvedMembersCount} Anggota",
                      style: AppTextStyles.regular.copyWith(color: Colors.grey[700], fontSize: 12)
                    ),
                  ] else ... [
                     Icon(Icons.group_add_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Baru", // Atau "0 Anggota"
                      style: AppTextStyles.regular.copyWith(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onJoinPressed, // Aksi sudah di-pass dari HomePage
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    textStyle: AppTextStyles.regular.copyWith(fontWeight: FontWeight.bold, fontSize: 13)
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
