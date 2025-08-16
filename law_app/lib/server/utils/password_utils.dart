import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for password hashing and verification
class PasswordUtils {
  static final PasswordUtils _instance = PasswordUtils._internal();
  
  // Singleton pattern
  factory PasswordUtils() {
    return _instance;
  }
  
  PasswordUtils._internal();
  
  /// Hash password with salt using SHA-256
  String hashPassword(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify if a password matches the hashed version
  bool verifyPassword(String password, String salt, String hashedPassword) {
    return hashPassword(password, salt) == hashedPassword;
  }
}