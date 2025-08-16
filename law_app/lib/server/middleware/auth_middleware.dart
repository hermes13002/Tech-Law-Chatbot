import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../config/env.dart';
import '../utils/response_utils.dart';

/// Authentication middleware for protecting routes
class AuthMiddleware {
  static final AuthMiddleware _instance = AuthMiddleware._internal();
  final _responseUtils = ResponseUtils();
  final _envConfig = EnvConfig();
  
  // Singleton pattern
  factory AuthMiddleware() {
    return _instance;
  }
  
  AuthMiddleware._internal();
  
  /// Middleware to check if the request has a valid JWT token
  /// 
  /// This middleware extracts the JWT token from the Authorization header,
  /// verifies it, and adds the user payload to the request context.
  Middleware checkAuth() {
    return (Handler handler) {
      return (Request request) async {
        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return _responseUtils.unauthorizedResponse('Missing or invalid Authorization header');
        }

        final token = authHeader.substring(7);
        try {
          final jwt = JWT.verify(token, SecretKey(_envConfig.jwtSecret));
          final updatedRequest = request.change(context: {'user': jwt.payload});
          return handler(updatedRequest);
        } catch (e) {
          return _responseUtils.unauthorizedResponse('Invalid token');
        }
      };
    };
  }
}