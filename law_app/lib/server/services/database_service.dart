import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../config/env.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// Service class for handling database operations
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final _envConfig = EnvConfig();
  
  late mongo.Db _db;
  late mongo.DbCollection _usersCollection;
  late mongo.DbCollection _conversationsCollection;
  late mongo.DbCollection _messagesCollection;
  
  // Singleton pattern
  factory DatabaseService() {
    return _instance;
  }
  
  DatabaseService._internal();
  
  /// Initialize the database connection
  Future<void> init() async {
    _db = await mongo.Db.create(_envConfig.dbUri);
    await _db.open();
    
    _usersCollection = _db.collection('users');
    _conversationsCollection = _db.collection('conversations');
    _messagesCollection = _db.collection('messages');
    
    print("Connected to MongoDB");
  }
  
  /// Close the database connection
  Future<void> close() async {
    await _db.close();
  }
  
  /// Get the users collection
  mongo.DbCollection get usersCollection => _usersCollection;
  
  /// Get the conversations collection
  mongo.DbCollection get conversationsCollection => _conversationsCollection;
  
  /// Get the messages collection
  mongo.DbCollection get messagesCollection => _messagesCollection;
  
  /// Find a user by email
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    return await _usersCollection.findOne({"email": email});
  }
  
  /// Find a user by ID
  Future<Map<String, dynamic>?> findUserById(String id) async {
    return await _usersCollection.findOne({"id": id});
  }
  
  /// Insert a new user
  Future<void> insertUser(User user) async {
    await _usersCollection.insertOne(user.toJson());
  }
  
  /// Find a conversation by ID
  Future<Map<String, dynamic>?> findConversationById(String id) async {
    return await _conversationsCollection.findOne({"id": id});
  }
  
  /// Find the most recent conversation for a user
  Future<Map<String, dynamic>?> findMostRecentConversation(String userId) async {
    final query = mongo.where.eq('userId', userId);
    query.sortBy('timestamp', descending: true);
    query.limit(1);
    return await _conversationsCollection.findOne(query);
  }
  
  /// Find all conversations for a user
  Future<List<Map<String, dynamic>>> findConversationsByUserId(String userId) async {
    final query = mongo.where.eq('userId', userId);
    query.sortBy('timestamp', descending: true);
    return await _conversationsCollection.find(query).toList();
  }
  
  /// Insert a new conversation
  Future<void> insertConversation(Conversation conversation) async {
    await _conversationsCollection.insertOne(conversation.toJson());
  }
  
  /// Find messages for a conversation
  Future<List<Map<String, dynamic>>> findMessagesByConversationId(
    String conversationId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final query = mongo.where.eq('conversationId', conversationId);
    query.sortBy('timestamp', descending: false);
    return await _messagesCollection
        .find(query)
        .skip(offset)
        .take(limit)
        .toList();
  }
  
  /// Count messages in a conversation
  Future<int> countMessagesInConversation(String conversationId) async {
    return await _messagesCollection
        .count(mongo.where.eq('conversationId', conversationId));
  }
  
  /// Insert a new message
  Future<void> insertMessage(Message message) async {
    await _messagesCollection.insertOne(message.toJson());
  }
  
  /// Find recent messages for a conversation (for context)
  Future<List<Map<String, dynamic>>> findRecentMessages(
    String conversationId, {
    int limit = 10,
  }) async {
    final query = mongo.where.eq('conversationId', conversationId);
    query.sortBy('timestamp', descending: true);
    query.limit(limit);
    
    var messages = await _messagesCollection.find(query).toList();
    return messages.reversed.toList(); // Reverse to get chronological order
  }
}