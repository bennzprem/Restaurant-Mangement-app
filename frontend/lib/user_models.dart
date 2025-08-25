// lib/models.dart

// This is the correct AppUser class that your ApiService needs.
class AppUser {
  final String id;
  final String? email;
  final String role;
  final String name;
  final String? avatarUrl;

  AppUser({
    required this.id,
    this.email,
    required this.role,
    required this.name,
    this.avatarUrl,
  });

  // This factory constructor is essential for the getAllUsers function.
  // It tells the app how to create an AppUser from database data.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      role: json['role'] ?? 'user',
      avatarUrl: json['avatar_url'],
    );
  }
}

// ... your other model classes like MenuCategory, CartItem, etc. can go below ...
