import 'user/user.dart';

class Group {
  final int id;
  final String name;
  final String? description;
  final User? creator; // User yang membuat grup
  final int? createdBy; // ID user yang membuat grup (jika creator tidak di-load penuh)
  final String? userStatusInGroup; // 'approved', 'pending', 'rejected', 'creator', atau null jika tidak ada info spesifik
  final int? approvedMembersCount; // Dari backend withCount
  final List<User>? approvedMembers; // Daftar anggota yang disetujui (jika di-load)
  final List<User>? pendingRequests; // Daftar permintaan bergabung (jika di-load dan user adalah admin)
  final DateTime? createdAt;
  final DateTime? updatedAt;


  Group({
    required this.id,
    required this.name,
    this.description,
    this.creator,
    this.createdBy,
    this.userStatusInGroup,
    this.approvedMembersCount,
    this.approvedMembers,
    this.pendingRequests,
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      creator: json['creator'] != null ? User.fromJson(json['creator']) : null,
      createdBy: json['created_by'],
      approvedMembersCount: json['approved_members_count'],
      // Jika ada pivot status dari relasi user ke group
      userStatusInGroup: json['pivot']?['status'],
      approvedMembers: (json['approved_members'] as List<dynamic>?)
          ?.map((m) => User.fromJson(m as Map<String, dynamic>))
          .toList(),
      pendingRequests: (json['pending_requests'] as List<dynamic>?)
          ?.map((m) => User.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}