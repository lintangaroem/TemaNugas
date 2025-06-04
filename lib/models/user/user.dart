class User {
  final int id;
  final String name;
  final String email;
  // Tambahkan field lain jika ada dari backend, misal avatar_url

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Tanpa Nama',
      email: json['email'] as String? ?? 'Tanpa Email',
    );
  }
}

