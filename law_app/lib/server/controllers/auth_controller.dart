import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../services/auth_service.dart';
import '../utils/response_utils.dart';

/// Controller class for handling authentication requests
class AuthController {
  static final AuthController _instance = AuthController._internal();
  final _authService = AuthService();
  final _responseUtils = ResponseUtils();
  
  // Singleton pattern
  factory AuthController() {
    return _instance;
  }
  
  AuthController._internal();
  
  /// Handle a registration request
  Future<Response> register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final name = body['name'];
      final email = body['email'];
      final password = body['password'];
      
      final result = await _authService.register(name, email, password);
      
      if (result.containsKey('error')) {
        return _responseUtils.errorResponse(
          result['error'],
          status: result['status'],
        );
      }
      
      return _responseUtils.successResponse(result);
    } catch (e) {
      return _responseUtils.errorResponse(e.toString());
    }
  }
  
  /// Handle a login request
  Future<Response> login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final email = body['email'];
      final password = body['password'];
      
      final result = await _authService.login(email, password);
      
      if (result.containsKey('error')) {
        return _responseUtils.errorResponse(
          result['error'],
          status: result['status'],
        );
      }
      
      return _responseUtils.successResponse(result);
    } catch (e) {
      return _responseUtils.errorResponse(e.toString());
    }
  }
  
  /// Handle a profile request
  Future<Response> getProfile(Request request) async {
    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final email = userData['email'];
      
      final result = await _authService.getProfile(email);
      
      if (result.containsKey('error')) {
        return _responseUtils.errorResponse(
          result['error'],
          status: result['status'],
        );
      }
      
      return _responseUtils.successResponse(result);
    } catch (e) {
      return _responseUtils.errorResponse(e.toString());
    }
  }
}