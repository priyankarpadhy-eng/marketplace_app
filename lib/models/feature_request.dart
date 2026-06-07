import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureRequest {
  final String id;
  final String title;
  final String description;
  final int votes;
  final List<String> voterIds;
  final String status;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  FeatureRequest({
    required this.id,
    required this.title,
    required this.description,
    this.votes = 0,
    this.voterIds = const [],
    this.status = 'pending',
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory FeatureRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FeatureRequest(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      votes: data['votes'] ?? 0,
      voterIds: List<String>.from(data['voterIds'] ?? []),
      status: data['status'] ?? 'pending',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'votes': votes,
      'voterIds': voterIds,
      'status': status,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
