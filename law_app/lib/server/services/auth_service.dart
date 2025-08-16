import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../config/env.dart';
import '../models/user.dart';
import '../utils/id_generator.dart';
import '../utils/password_utils.dart';
import 'database_service.dart';

/// Service class for handling authentication operations
class AuthService {
  static final AuthService _instance = AuthService._internal();
  final _envConfig = EnvConfig();
  final _idGenerator = IdGenerator();
  final _passwordUtils = PasswordUtils();
  final _databaseService = DatabaseService();
  
  // Singleton pattern
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  /// Register a new user
  /// 
  /// Returns a map with the result of the registration
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    // Check if user already exists
    final existingUser = await _databaseService.findUserByEmail(email);
    if (existingUser != null) {
      return {"error": "User already exists", "status": 400};
    }
    
    // Generate unique user ID, salt, and hash the password
    final userId = _idGenerator.generateUserId();
    final salt = _idGenerator.generateSalt();
    final hashedPassword = _passwordUtils.hashPassword(password, salt);
    
    // Create and insert the new user
    final user = User(
      id: userId,
      name: name,
      email: email,
      password: hashedPassword,
      salt: salt,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    await _databaseService.insertUser(user);
    
    return {
      "message": "Registration successful",
      "userId": userId,
      "name": name,
      "email": email,
      "status": 200,
    };
  }
  
  /// Login a user
  /// 
  /// Returns a map with the result of the login
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Find the user by email
    final user = await _databaseService.findUserByEmail(email);
    if (user == null) {
      return {"error": "Invalid credentials", "status": 401};
    }
    
    // Verify the password
    final hashedPassword = _passwordUtils.hashPassword(password, user['salt']);
    if (hashedPassword != user['password']) {
      return {"error": "Invalid credentials", "status": 401};
    }
    
    // Generate a JWT token
    final jwt = JWT({
      "email": email,
      "userId": user['id'],
    });
    
    final token = jwt.sign(
      SecretKey(_envConfig.jwtSecret),
      expiresIn: Duration(hours: 1),
    );
    
    return {
      "message": "Login successful",
      "token": token,
      "email": email,
      "userId": user['id'],
      "status": 200,
    };
  }
  
  /// Get a user's profile
  /// 
  /// Returns a map with the user's profile data
  Future<Map<String, dynamic>> getProfile(String email) async {
    final user = await _databaseService.findUserByEmail(email);
    if (user == null) {
      return {"error": "User not found", "status": 404};
    }
    
    // Remove sensitive fields
    final responseData = Map<String, dynamic>.from(user);
    responseData.addAll({'message': 'Profile gotten successfully'});
    responseData.remove('_id');
    responseData.remove('password');
    responseData.remove('salt');
    
    return responseData;
  }
  
  /// Verify a JWT token
  /// 
  /// Returns the payload if the token is valid, null otherwise
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_envConfig.jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}