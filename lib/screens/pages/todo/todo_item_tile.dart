import 'package:flutter/material.dart';
import 'package:teman_nugas/models/todo.dart'; // Sesuaikan path jika perlu
import 'package:teman_nugas/constants/constant.dart'; // Sesuaikan path jika perlu

class TodoItemTile extends StatelessWidget {
  final Todo todo;
  final bool canModify; // Apakah user saat ini bisa memodifikasi (update status, hapus)
  final Function(bool?)? onStatusChanged;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onTap; // Untuk edit judul todo jika diperlukan

  const TodoItemTile({
    super.key,
    required this.todo,
    required this.canModify,
    this.onStatusChanged,
    this.onDeletePressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        onTap: canModify ? onTap : null, // Hanya bisa tap untuk edit jika bisa modifikasi
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: canModify ? onStatusChanged : null, // Hanya bisa ubah status jika bisa modifikasi
          activeColor: AppColors.primaryBlue,
          // VisualDensity lebih kecil agar checkbox tidak terlalu besar
          visualDensity: VisualDensity.compact,
          side: BorderSide(
            color: todo.isCompleted ? AppColors.primaryBlue : AppColors.textLight.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        title: Text(
          todo.title,
          style: todo.isCompleted
              ? AppTextStyles.bodyLarge.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                )
              : AppTextStyles.bodyLarge,
        ),
        trailing: canModify && onDeletePressed != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.redAlert, size: 22),
                tooltip: "Hapus Tugas",
                onPressed: onDeletePressed,
              )
            : null,
      ),
    );
  }
}
