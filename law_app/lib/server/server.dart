import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'config/env.dart';
import 'middleware/auth_middleware.dart';
import 'routes/public_routes.dart';
import 'routes/private_routes.dart';
import 'routes/chat_routes.dart';
import 'services/database_service.dart';

/// Main server class
class Server {
  static final Server _instance = Server._internal();
  final _envConfig = EnvConfig();
  final _databaseService = DatabaseService();
  final _authMiddleware = AuthMiddleware();
  final _publicRoutes = PublicRoutes();
  final _privateRoutes = PrivateRoutes();
  final _chatRoutes = ChatRoutes();
  
  // Singleton pattern
  factory Server() {
    return _instance;
  }
  
  Server._internal();
  
  /// Start the server
  Future<void> start() async {
    // Initialize the database connection
    await _databaseService.init();
    
    // Create the handler
    final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(_routeRequest);
    
    // Get host and port from environment variables or use defaults
    final host = Platform.environment['HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['PORT'] ?? '8080');
    
    // Start the server
    final server = await serve(handler, host, port);
    print('Server running at http://${server.address.host}:${server.port}');
  }
  
  /// Route the request to the appropriate handler
  Future<Response> _routeRequest(Request request) async {
    // Path matching
    if (request.url.path.startsWith('profile')) {
      final pipeline = Pipeline()
          .addMiddleware(_authMiddleware.checkAuth());
      return pipeline.addHandler(_privateRoutes.router)(request);
    }

    if (request.url.path.startsWith('chat')) {
      final pipeline = Pipeline()
          .addMiddleware(_authMiddleware.checkAuth());
      return pipeline.addHandler(_chatRoutes.router)(request);
    }
    
    // Handle conversations endpoint
    if (request.url.path.startsWith('conversations/')) {
      final pipeline = Pipeline()
          .addMiddleware(_authMiddleware.checkAuth());
      return pipeline.addHandler(_chatRoutes.router)(request);
    }
    
    // API endpoints with /api prefix
    if (request.url.path.startsWith('history')) {
      final pipeline = Pipeline()
          .addMiddleware(_authMiddleware.checkAuth());
      return pipeline.addHandler(_chatRoutes.router)(request);
    }
    
    if (request.url.path.startsWith('api/chat/conversations/')) {
      final conversationId = request.url.pathSegments[3];
      final pipeline = Pipeline()
          .addMiddleware(_authMiddleware.checkAuth());
      return pipeline.addHandler((req) async {
        return await _chatRoutes.router.call(
            req.change(path: 'conversations/$conversationId/messages'));
      })(request);
    }
    
    return _publicRoutes.router(request);
  }
}