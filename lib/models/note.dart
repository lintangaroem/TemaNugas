// lib/models/note.dart
import 'user/user.dart';

class Note {
  final int id;
  final int projectId;
  final String? title; // Judul note bisa opsional
  final String content;
  final int createdByUserId;
  final User? creator;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.projectId,
    this.title,
    required this.content,
    required this.createdByUserId,
    this.creator,
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      createdByUserId: json['created_by_user_id'] as int,
      creator: json['creator'] != null ? User.fromJson(json['creator'] as Map<String, dynamic>) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'title': title,
      'content': content,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'title': title,
      'content': content,
    };
  }
}
