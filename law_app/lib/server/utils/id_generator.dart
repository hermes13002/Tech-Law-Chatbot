import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:uuid/uuid.dart';

/// Utility class for generating various IDs used in the application
class IdGenerator {
  static final IdGenerator _instance = IdGenerator._internal();
  final _uuid = Uuid();
  final _rnd = Random.secure();
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  
  // Singleton pattern
  factory IdGenerator() {
    return _instance;
  }
  
  IdGenerator._internal();
  
  /// Generate a unique conversation ID with 'conv_' prefix
  String generateConversationId() {
    return 'conv_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';
  }
  
  /// Generate a sequential message ID with 'msg_' prefix and zero-padding (msg_001, msg_002, etc.)
  Future<String> generateSequentialMessageId(mongo.DbCollection messagesCollection, String conversationId) async {
    // Count existing messages in this conversation
    final count = await messagesCollection
        .count(mongo.where.eq('conversationId', conversationId));
    
    // Format with zero-padding (e.g., msg_001, msg_002, etc.)
    final paddedNumber = (count + 1).toString().padLeft(3, '0');
    return 'msg_$paddedNumber'; 
  }
  
  /// Generate a random salt for password hashing
  String generateSalt([int length = 32]) {
    return List.generate(length, (index) => _chars[_rnd.nextInt(_chars.length)]).join();
  }
  
  /// Generate a unique user ID with 'usr_' prefix
  String generateUserId() {
    return 'usr_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';
  }
}