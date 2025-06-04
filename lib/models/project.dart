import 'user/user.dart';
import 'todo.dart'; // Akan kita buat
import 'note.dart'; // Akan kita buat

class Project {
  final int id;
  final String name;
  final String? description;
  final DateTime? deadline;
  final String status;
  final int createdBy; // ID user pembuat
  final User? creator; // Objek User pembuat (jika di-load dari backend)
  final List<User>? approvedMembers; // Anggota yang disetujui
  final List<User>? pendingRequests; // Permintaan bergabung yang pending
  final List<Todo>? todos; // Daftar todos dalam proyek (jika di-load)
  final List<Note>? notes; // Daftar notes dalam proyek (jika di-load)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.deadline,
    required this.status,
    required this.createdBy,
    this.creator,
    this.approvedMembers,
    this.pendingRequests,
    this.todos,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Tanpa Nama Proyek',
      description: json['description'] as String?,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      status: json['status'] as String? ?? 'pending',
      createdBy: json['created_by'] as int,
      creator: json['creator'] != null ? User.fromJson(json['creator'] as Map<String, dynamic>) : null,
      approvedMembers: (json['approved_members'] as List<dynamic>?)
          ?.map((m) => User.fromJson(m as Map<String, dynamic>))
          .toList(),
      pendingRequests: (json['pending_requests'] as List<dynamic>?)
          ?.map((m) => User.fromJson(m as Map<String, dynamic>))
          .toList(),
      todos: (json['todos'] as List<dynamic>?)
          ?.map((t) => Todo.fromJson(t as Map<String, dynamic>))
          .toList(),
      notes: (json['notes'] as List<dynamic>?)
          ?.map((n) => Note.fromJson(n as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  bool isCreator(int? currentUserId) {
    return createdBy == currentUserId;
  }
}
