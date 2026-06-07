import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final int likes;
  final DateTime createdAt;
  final bool isReply;

  PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.likes = 0,
    required this.createdAt,
    this.isReply = false,
  });

  factory PostComment.fromFirestore(DocumentSnapshot doc, {bool isReply = false}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      likes: data['likes'] ?? 0,
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isReply: isReply,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'likes': likes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
