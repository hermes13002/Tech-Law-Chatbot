import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../utils/id_generator.dart';
import '../utils/markdown_utils.dart';
import 'database_service.dart';

/// Service class for handling chat operations
class ChatService {
  static final ChatService _instance = ChatService._internal();
  final _envConfig = EnvConfig();
  final _idGenerator = IdGenerator();
  final _markdownUtils = MarkdownUtils();
  final _databaseService = DatabaseService();
  
  // Base system prompt for the AI
  static const String _baseSystemPrompt = 
    "You are a highly knowledgeable legal assistant trained in diverse areas of law including: "
    "contract law, constitutional law, tort law, property law, criminal law, family law, employment law, "
    "intellectual property law, corporate law, tax law, immigration law, environmental law, healthcare law, "
    "international law, administrative law, bankruptcy law, securities law, civil procedure, and legal ethics. "
    "\n\n"
    "STRICT OPERATIONAL BOUNDARIES: "
    "\n"
    "1. You MUST ONLY respond to inquiries that are explicitly legal in nature. "
    "2. You MUST IMMEDIATELY IDENTIFY non-legal queries by checking if they relate to: "
    "   - Legal principles, statutes, regulations, or case law "
    "   - Legal procedures, rights, or obligations "
    "   - Legal document analysis or preparation "
    "   - Legal implications of specific scenarios "
    "\n"
    "3. For ANY query that falls outside these legal parameters—including but not limited to: "
    "   - General knowledge questions "
    "   - Personal advice (financial, relationship, career, etc.) "
    "   - Medical, technical, or scientific information "
    "   - Political opinions or predictions "
    "   - Entertainment, sports, or cultural topics "
    "   - Requests for illegal activities or unethical advice "
    "   - Hypothetical scenarios without legal relevance "
    "   YOU MUST respond ONLY with: 'I'm designed exclusively to assist with legal questions. Your inquiry appears to be outside my legal scope. Please rephrase your question to focus on a specific legal matter, and I'll be happy to help.' "
    "\n"
    "4. For ambiguous queries that contain both legal and non-legal elements, ONLY address the legal aspects and explicitly note that you're focusing solely on the legal dimensions. "
    "\n"
    "5. Always include appropriate disclaimers that your responses: "
    "   - Do not constitute legal advice "
    "   - Cannot replace consultation with a licensed attorney "
    "   - May not reflect the most current legal developments "
    "   - May not account for jurisdictional differences "
    "\n"
    "6. When appropriate, cite relevant legal sources and note jurisdictional limitations. "
    "\n"
    "7. Maintain a professional, neutral tone appropriate for legal discourse. "
    "\n"
    "Remember: You are NOT a replacement for a licensed attorney and must make this clear in your responses.";
  
  // Singleton pattern
  factory ChatService() {
    return _instance;
  }
  
  ChatService._internal();
  
  /// Process a user message and get a response from the AI
  /// 
  /// Returns a map with the result of the operation
  Future<Map<String, dynamic>> processMessage({
    required String userId,
    required String message,
    String? conversationId,
    bool createNewConversation = false,
  }) async {
    try {
      // Determine which conversation to use
      String actualConversationId;
      bool isNewConversation = false;
      
      if (conversationId == null || conversationId.isEmpty) {
        // Check if user explicitly wants a new conversation
        if (createNewConversation) {
          // Create a new conversation
          actualConversationId = _idGenerator.generateConversationId();
          isNewConversation = true;
        } else {
          // Try to find the most recent conversation for this user
          final recentConversation = await _databaseService.findMostRecentConversation(userId);
          
          if (recentConversation != null) {
            // Use the most recent conversation
            actualConversationId = recentConversation['id'] as String;
          } else {
            // No existing conversations, create a new one
            actualConversationId = _idGenerator.generateConversationId();
            isNewConversation = true;
          }
        }
        
        // If we need to create a new conversation
        if (isNewConversation) {
          // Create a title from the first message (limited to first 50 chars)
          String title = message.length > 50 
              ? '${message.substring(0, 47)}...' 
              : message;
          
          // Create and insert the new conversation
          final conversation = Conversation(
            id: actualConversationId,
            userId: userId,
            title: title,
            timestamp: DateTime.now().toIso8601String(),
          );
          
          await _databaseService.insertConversation(conversation);
        }
      } else {
        // Use the provided conversationId
        actualConversationId = conversationId;
      }
      
      // Store the user message with sequential ID
      final userMessageId = await _idGenerator.generateSequentialMessageId(
        _databaseService.messagesCollection, 
        actualConversationId
      );
      
      final userMessageObj = Message.createUserMessage(
        id: userMessageId,
        conversationId: actualConversationId,
        content: message,
      );
      
      await _databaseService.insertMessage(userMessageObj);
      
      // Get response from Groq with conversation context
      final aiResponseData = await _handleGroqRequest(message, actualConversationId);
      
      // Store the AI response if it's a valid legal response
      if (aiResponseData.containsKey('response')) {
        final aiMessageId = await _idGenerator.generateSequentialMessageId(
          _databaseService.messagesCollection, 
          actualConversationId
        );
        
        final aiMessageObj = Message.createAiMessage(
          id: aiMessageId,
          conversationId: actualConversationId,
          content: aiResponseData['response'],
        );
        
        await _databaseService.insertMessage(aiMessageObj);
      }
      
      // Add conversationId to the response
      final responseWithConversationId = Map<String, dynamic>.from(aiResponseData);
      responseWithConversationId['conversationId'] = actualConversationId;
      
      return responseWithConversationId;
    } catch (e) {
      return {"error": e.toString(), "status": 400};
    }
  }
  
  /// Get all conversations for a user
  /// 
  /// Returns a list of conversations
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      // Find all conversations for this user, sorted by timestamp (newest first)
      final conversations = await _databaseService.findConversationsByUserId(userId);
      
      // Format the response
      final List<Map<String, dynamic>> formattedConversations = conversations.map((conv) {
        return {
          "id": conv['id'],
          "title": conv['title'],
          "timestamp": conv['timestamp'],
        };
      }).toList();
      
      return formattedConversations;
    } catch (e) {
      return [];
    }
  }
  
  /// Get all messages for a specific conversation
  /// 
  /// Returns a map with the conversation and its messages
  Future<Map<String, dynamic>> getConversationMessages(
    String conversationId, 
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Verify the conversation belongs to this user
      final conversation = await _databaseService.findConversationById(conversationId);
      
      if (conversation == null || conversation['userId'] != userId) {
        return {"error": "Conversation not found", "status": 404};
      }
      
      // Find all messages for this conversation, sorted by timestamp
      final messages = await _databaseService.findMessagesByConversationId(
        conversationId,
        limit: limit,
        offset: offset,
      );
      
      // Format the response
      final List<Map<String, dynamic>> formattedMessages = messages.map((msg) {
        return {
          "id": msg['id'],
          "sender": msg['sender'],
          "content": msg['content'],
          "timestamp": msg['timestamp'],
        };
      }).toList();
      
      return {
        "id": conversationId,
        "title": conversation['title'],
        "messages": formattedMessages,
      };
    } catch (e) {
      return {"error": e.toString(), "status": 500};
    }
  }
  
  /// Handle a request to the Groq API
  /// 
  /// Returns a map with the response from the API
  Future<Map<String, dynamic>> _handleGroqRequest(
    String userMessage, 
    String conversationId,
  ) async {
    // Create system prompt with conversation ID for better context awareness
    final String systemPrompt = 
      "$_baseSystemPrompt\n\nYou are currently in conversation: $conversationId. "
      "Maintain context awareness for this specific conversation.";
      
    // Fetch the last 10 messages from this conversation for context
    final recentMessages = await _databaseService.findRecentMessages(conversationId);
    
    // Format messages for the API
    final List<Map<String, String>> formattedMessages = [
      {"role": "system", "content": systemPrompt}
    ];
    
    // Add conversation history
    for (final msg in recentMessages) {
      final role = msg['sender'] == 'user' ? 'user' : 'assistant';
      formattedMessages.add({
        "role": role,
        "content": msg['content']
      });
    }
    
    // Add the current message if it's not already included
    if (recentMessages.isEmpty || 
        recentMessages.last['content'] != userMessage) {
      formattedMessages.add({
        "role": "user",
        "content": userMessage
      });
    }
    
    final response = await http.post(
      Uri.parse(_envConfig.groqApiUrl),
      headers: {
        'Authorization': 'Bearer ${_envConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "messages": formattedMessages,
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "temperature": 0.7,
        "max_tokens": 2048,
        "top_p": 1,
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      String reply = data['choices'][0]['message']['content'];

      // Clean the reply for markdown, escape characters
      reply = _markdownUtils.stripMarkdownAndHtml(reply);
      
      return {
        "response": reply,
        "is_legal_response": !reply.toLowerCase().contains("i'm designed exclusively to assist with legal questions")
      };
    } else {
      return {
        "error": "Groq API error",
        "details": response.body
      };
    }
  }
}