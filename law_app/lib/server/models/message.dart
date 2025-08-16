/// Model class for a message in a conversation
class Message {
  final String id;
  final String conversationId;
  final String sender;
  final String content;
  final String timestamp;
  
  /// Constructor
  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.timestamp,
  });
  
  /// Create a Message from a JSON map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
  
  /// Convert this Message to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
    };
  }
  
  /// Create a copy of this Message with the given fields replaced
  Message copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? content,
    String? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  /// Create a new user message
  factory Message.createUserMessage({
    required String id,
    required String conversationId,
    required String content,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      sender: 'user',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
  
  /// Create a new AI message
  factory Message.createAiMessage({
    required String id,
    required String conversationId,
    required String content,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      sender: 'ai',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}