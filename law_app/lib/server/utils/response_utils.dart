import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Utility class for handling HTTP responses
class ResponseUtils {
  static final ResponseUtils _instance = ResponseUtils._internal();
  
  // Singleton pattern
  factory ResponseUtils() {
    return _instance;
  }
  
  ResponseUtils._internal();
  
  /// Create a JSON response with the given data and status code
  Response jsonResponse(Map<String, dynamic> data, {int status = 200}) {
    return Response(
      status, 
      body: jsonEncode(data), 
      headers: {'Content-Type': 'application/json'}
    );
  }
  
  /// Create a success response with the given data
  Response successResponse(Map<String, dynamic> data) {
    return jsonResponse(data);
  }
  
  /// Create an error response with the given message and status code
  Response errorResponse(String message, {int status = 400}) {
    return jsonResponse({'error': message}, status: status);
  }
  
  /// Create an unauthorized response
  Response unauthorizedResponse([String message = 'Unauthorized']) {
    return jsonResponse({'error': message}, status: 401);
  }
  
  /// Create a not found response
  Response notFoundResponse([String message = 'Not found']) {
    return jsonResponse({'error': message}, status: 404);
  }
}