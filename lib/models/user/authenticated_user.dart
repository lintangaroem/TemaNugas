import 'user.dart';
import '../project.dart';

class AuthenticatedUser extends User {
  final List<Project> createdProjects;
  final List<Project> approvedProjects;
  final List<Project> pendingProjectRequests;

  AuthenticatedUser({
    required super.id,
    required super.name,
    required super.email,
    this.createdProjects = const [],
    this.approvedProjects = const [],
    this.pendingProjectRequests = const [],
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Tanpa Nama',
      email: json['email'] as String? ?? 'Tanpa Email',
      createdProjects: (json['created_projects'] as List<dynamic>?)
              ?.map((p) => Project.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      approvedProjects: (json['approved_projects'] as List<dynamic>?)
              ?.map((p) => Project.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      pendingProjectRequests: (json['pending_project_requests'] as List<dynamic>?)
              ?.map((p) => Project.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
