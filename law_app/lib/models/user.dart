class User {
  final String id;
  final String name;
  final String email;
  final String? createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}