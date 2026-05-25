enum ChatMessageType { user, ai }

class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      type: json['type'] == 'user' ? ChatMessageType.user : ChatMessageType.ai,
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == ChatMessageType.user ? 'user' : 'ai',
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}