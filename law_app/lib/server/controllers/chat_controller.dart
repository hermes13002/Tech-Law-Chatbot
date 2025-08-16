import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../services/chat_service.dart';
import '../utils/response_utils.dart';

/// Controller class for handling chat requests
class ChatController {
  static final ChatController _instance = ChatController._internal();
  final _chatService = ChatService();
  final _responseUtils = ResponseUtils();
  
  // Singleton pattern
  factory ChatController() {
    return _instance;
  }
  
  ChatController._internal();
  
  /// Handle a chat message request
  Future<Response> processMessage(Request request) async {
    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final userId = userData['userId'];
      
      final body = await request.readAsString();
      final Map<String, dynamic> data = jsonDecode(body);
      final String userMessage = data['message'];
      
      // Check if conversationId is provided
      String? providedConversationId = data['conversationId'];
      bool createNewConversation = data['createNewConversation'] == true;
      
      final result = await _chatService.processMessage(
        userId: userId,
        message: userMessage,
        conversationId: providedConversationId,
        createNewConversation: createNewConversation,
      );
      
      if (result.containsKey('error')) {
        return _responseUtils.errorResponse(
          result['error'],
          status: result['status'] ?? 400,
        );
      }
      
      return _responseUtils.successResponse(result);
    } catch (e) {
      return _responseUtils.errorResponse(e.toString());
    }
  }
  
  /// Handle a request to get conversation history
  Future<Response> getConversations(Request request) async {
    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final userId = userData['userId'];
      
      final conversations = await _chatService.getConversations(userId);
      
      return _responseUtils.successResponse({
        "conversations": conversations
      });
    } catch (e) {
      return _responseUtils.errorResponse(e.toString(), status: 500);
    }
  }
  
  /// Handle a request to get messages for a conversation
  Future<Response> getConversationMessages(Request request, String conversationId) async {
    try {
      final userData = request.context['user'] as Map<String, dynamic>;
      final userId = userData['userId'];
      
      // Parse pagination parameters
      final params = request.url.queryParameters;
      int limit = 20;
      int offset = 0;
      
      if (params.containsKey('limit')) {
        limit = int.tryParse(params['limit'] ?? '20') ?? 20;
      }
      
      if (params.containsKey('offset')) {
        offset = int.tryParse(params['offset'] ?? '0') ?? 0;
      }
      
      final result = await _chatService.getConversationMessages(
        conversationId,
        userId,
        limit: limit,
        offset: offset,
      );
      
      if (result.containsKey('error')) {
        return _responseUtils.errorResponse(
          result['error'],
          status: result['status'] ?? 500,
        );
      }
      
      return _responseUtils.successResponse(result);
    } catch (e) {
      return _responseUtils.errorResponse(e.toString(), status: 500);
    }
  }
}