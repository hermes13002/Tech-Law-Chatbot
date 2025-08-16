import 'package:shelf_router/shelf_router.dart';

import '../controllers/auth_controller.dart';

/// Class for defining private (authenticated) routes
class PrivateRoutes {
  static final PrivateRoutes _instance = PrivateRoutes._internal();
  final _authController = AuthController();
  
  // Singleton pattern
  factory PrivateRoutes() {
    return _instance;
  }
  
  PrivateRoutes._internal();
  
  /// Create and return a router with private routes
  Router get router {
    final router = Router();
    
    // Profile route
    router.get('/profile', _authController.getProfile);
    
    return router;
  }
}