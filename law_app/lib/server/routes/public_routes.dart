import 'package:shelf_router/shelf_router.dart';

import '../controllers/auth_controller.dart';

/// Class for defining public routes
class PublicRoutes {
  static final PublicRoutes _instance = PublicRoutes._internal();
  final _authController = AuthController();
  
  // Singleton pattern
  factory PublicRoutes() {
    return _instance;
  }
  
  PublicRoutes._internal();
  
  /// Create and return a router with public routes
  Router get router {
    final router = Router();
    
    // Registration route
    router.post('/register', _authController.register);
    
    // Login route
    router.post('/login', _authController.login);
    
    return router;
  }
}