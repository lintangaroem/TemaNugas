class Project {
  final int id;
  final int groupId;
  final String name;
  final String? description;
  final DateTime? deadline;
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  var group;

  Project({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    this.deadline,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      groupId: json['group_id'],
      name: json['name'],
      description: json['description'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
