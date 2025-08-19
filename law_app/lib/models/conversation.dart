class Conversation {
  final String id;
  final String title;
  final String timestamp;
  
  Conversation({
    required this.id,
    required this.title,
    required this.timestamp,
  });
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Conversation',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp,
    };
  }
}