// lib/models/todo.dart
import 'user/user.dart';

class Todo {
  final int id;
  final int projectId;
  final String title;
  bool isCompleted; // Non-final agar bisa diubah statusnya di UI
  final int? createdByUserId;
  final User? creator;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Todo({
    required this.id,
    required this.projectId,
    required this.title,
    required this.isCompleted,
    this.createdByUserId,
    this.creator,
    this.createdAt,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      title: json['title'] as String? ?? 'Tanpa Judul',
      isCompleted: json['is_completed'] as bool? ?? false,
      createdByUserId: json['created_by_user_id'] as int?,
      creator: json['creator'] != null ? User.fromJson(json['creator'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'title': title,
      // 'is_completed' bisa di-default false oleh backend
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'title': title,
      'is_completed': isCompleted,
    };
  }
}
