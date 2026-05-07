import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system }

enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    this.status = MessageStatus.sent,
    DateTime? timestamp,
    this.isStreaming = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  ChatMessage copyWith({
    String? content,
    MessageRole? role,
    MessageStatus? status,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role ?? this.role,
      status: status ?? this.status,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.name,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String?,
    content: j['content'] as String? ?? '',
    role: MessageRole.values.firstWhere(
      (e) => e.name == j['role'],
      orElse: () => MessageRole.user,
    ),
    status: MessageStatus.sent,
    timestamp: j['timestamp'] != null ? DateTime.parse(j['timestamp'] as String) : null,
  );
}
