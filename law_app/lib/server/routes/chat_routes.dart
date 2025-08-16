import 'package:shelf_router/shelf_router.dart';

import '../controllers/chat_controller.dart';

/// Class for defining chat-related routes
class ChatRoutes {
  static final ChatRoutes _instance = ChatRoutes._internal();
  final _chatController = ChatController();
  
  // Singleton pattern
  factory ChatRoutes() {
    return _instance;
  }
  
  // Private constructor for singleton
  ChatRoutes._internal();
  
  /// Create and return a router with chat routes
  Router get router {
    final router = Router();
    
    // Chat message route
    router.post('/chat', _chatController.processMessage);
    
    // Conversation history route
    router.get('/history', _chatController.getConversations);
    
    // Conversation messages route
    router.get('/conversations/<conversationId>/messages', _chatController.getConversationMessages);
    
    return router;
  }
}