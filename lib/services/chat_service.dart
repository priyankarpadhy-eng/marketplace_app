import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChatConversation>> watchConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participant_ids', arrayContains: userId)
        .orderBy('last_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Stream<List<ChatMessage>> watchMessages(String convId, String userId) {
    return _db
        .collection('messages')
        .where('conversation_id', isEqualTo: convId)
        .orderBy('sent_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap({'id': doc.id, ...doc.data()}, userId))
            .toList());
  }

  Future<void> sendMessage(String convId, ChatMessage message) async {
    await _db.collection('messages').add({
      'conversation_id': convId,
      'sender_id': message.senderId,
      'sender_name': message.senderName,
      'content': message.content,
      'sent_at': DateTime.now().toIso8601String(),
    });

    await _db.collection('conversations').doc(convId).update({
      'last_message': message.content,
      'last_time': DateTime.now().toIso8601String(),
    });
  }

  Future<String> startConversation({
    required String currentUserId,
    required String currentUserName,
    required String targetUserId,
    required String targetUserName,
  }) async {
    // Check if exists
    final query = await _db
        .collection('conversations')
        .where('participant_ids', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final ids = List<String>.from(doc.data()['participant_ids'] ?? []);
      if (ids.contains(targetUserId)) {
        return doc.id;
      }
    }

    // Create new
    final newConv = await _db.collection('conversations').add({
      'name': targetUserName,
      'participant_ids': [currentUserId, targetUserId],
      'participants': [
        {'uid': currentUserId, 'name': currentUserName},
        {'uid': targetUserId, 'name': targetUserName},
      ],
      'type': 'private',
      'last_message': 'Conversation started',
      'last_time': DateTime.now().toIso8601String(),
    });

    return newConv.id;
  }
}
