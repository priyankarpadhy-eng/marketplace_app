import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String name;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastTime;
  final List<Map<String, String>> participants;
  final String? type;

  ChatConversation({
    required this.id,
    required this.name,
    required this.participantIds,
    required this.lastMessage,
    required this.lastTime,
    required this.participants,
    this.type = 'private',
  });

  factory ChatConversation.fromMap(Map<String, dynamic> data) {
    return ChatConversation(
      id: data['id'] as String,
      name: data['name'] ?? 'Chat',
      participantIds: List<String>.from(data['participant_ids'] ?? []),
      lastMessage: data['last_message'] ?? '',
      lastTime: data['last_time'] != null 
          ? DateTime.parse(data['last_time'] as String) 
          : DateTime.now(),
      participants: (data['participants'] as List?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? [],
      type: data['type'],
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isOwn = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String currentUserId) {
    return ChatMessage(
      id: data['id'] as String,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? 'User',
      content: data['content'] ?? '',
      sentAt: data['sent_at'] != null 
          ? DateTime.parse(data['sent_at'] as String) 
          : DateTime.now(),
      isOwn: (data['sender_id'] ?? '') == currentUserId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}
