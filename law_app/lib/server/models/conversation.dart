/// Model class for a conversation
class Conversation {
  final String id;
  final String userId;
  final String title;
  final String timestamp;
  
  /// Constructor
  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.timestamp,
  });
  
  /// Create a Conversation from a JSON map
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
  
  /// Convert this Conversation to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'timestamp': timestamp,
    };
  }
  
  /// Create a copy of this Conversation with the given fields replaced
  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    String? timestamp,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  /// Create a new Conversation with the current timestamp
  factory Conversation.create({
    required String id,
    required String userId,
    required String title,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      title: title,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}