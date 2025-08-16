/// Model class for a user
class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String salt;
  final String createdAt;
  
  /// Constructor
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.salt,
    required this.createdAt,
  });
  
  /// Create a User from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      salt: json['salt'] as String,
      createdAt: json['created_at'] as String,
    );
  }
  
  /// Convert this User to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'salt': salt,
      'created_at': createdAt,
    };
  }
  
  /// Create a copy of this User with the given fields replaced
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? salt,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      salt: salt ?? this.salt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Create a User for public consumption (without sensitive fields)
  Map<String, dynamic> toPublicJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt,
    };
  }
}