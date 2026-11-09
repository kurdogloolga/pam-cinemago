class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final email = json['email'] as String;
    if (id <= 0 || name.trim().isEmpty || email.trim().isEmpty) {
      throw const FormatException('Invalid user profile');
    }
    return UserProfile(id: id, name: name, email: email);
  }
}
