import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Base URL for the API
  final String baseUrl = 'https://tlc-shelf-api.globeapp.dev';
  
  // Token storage keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  
  // Headers for authenticated requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return token != null;
  }
  
  // Get stored user data
  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(userIdKey),
      'email': prefs.getString(userEmailKey),
      'name': prefs.getString(userNameKey),
    };
  }
  
  // Store authentication data
  Future<void> storeAuthData(String token, String userId, String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userIdKey, userId);
    await prefs.setString(userEmailKey, email);
    await prefs.setString(userNameKey, name);
  }
  
  // Clear authentication data (logout)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userNameKey);
  }
  
  // Register a new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // Login a user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Store authentication data
        await storeAuthData(
          data['token'], 
          data['userId'], 
          email,
          data['name'] ?? '',
        );
        return data;
      } else {
        return {'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // Send a chat message
  Future<Map<String, dynamic>> sendMessage(String message, {String? conversationId, bool createNewConversation = false}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'conversationId': conversationId,
          'createNewConversation': createNewConversation,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['error'] ?? 'Failed to send message'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // Get conversation history
  Future<Map<String, dynamic>> getConversations() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['error'] ?? 'Failed to get conversations'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // Get messages for a specific conversation
  Future<Map<String, dynamic>> getConversationMessages(String conversationId, {int limit = 20, int offset = 0}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId/messages?limit=$limit&offset=$offset'),
        headers: headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['error'] ?? 'Failed to get messages'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}