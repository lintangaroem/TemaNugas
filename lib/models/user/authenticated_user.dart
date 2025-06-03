import 'user.dart';
import '../group.dart';

class AuthenticatedUser extends User {
  final List<Group> approvedGroups;
  final List<Group> pendingGroupRequests;
  final List<Group> createdGroups;

  AuthenticatedUser({
    required super.id,
    required super.name,
    required super.email,
    this.approvedGroups = const [],
    this.pendingGroupRequests = const [],
    this.createdGroups = const [],
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      approvedGroups: (json['approved_groups'] as List<dynamic>?)
              ?.map((g) => Group.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      pendingGroupRequests: (json['pending_group_requests'] as List<dynamic>?)
              ?.map((g) => Group.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      createdGroups: (json['created_groups'] as List<dynamic>?)
              ?.map((g) => Group.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
