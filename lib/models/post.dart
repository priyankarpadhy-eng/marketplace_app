import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorNickname;
  final String? authorAvatar;
  final DateTime createdAt;
  final String tag;
  final int votes;
  final int commentsCount;
  final List<String> likedBy;
  final String? image;
  final List<String>? images;
  final String? video;
  
  // Freelancing specific
  final String? budget;
  final String? contact;
  
  // Custom styles
  final String? textStyle;
  final bool isBold;

  Post({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorNickname,
    this.authorAvatar,
    required this.createdAt,
    required this.tag,
    this.votes = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.image,
    this.images,
    this.video,
    this.budget,
    this.contact,
    this.textStyle,
    this.isBold = false,
  });

  bool get isImmortal => votes >= 50;

  int get daysLeft {
    final now = DateTime.now();
    final age = now.difference(createdAt).inDays;
    return (7 - age).clamp(0, 7);
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? data['author'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorNickname: data['authorNickname'],
      authorAvatar: data['authorAvatar'],
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(), // Fallback for local changes or missing field
      tag: data['tag'] ?? 'discussion',
      votes: data['votes'] ?? 0,
      commentsCount: data['comments'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      image: data['image'],
      images: data['images'] != null 
          ? List<String>.from(data['images']) 
          : (data['image'] != null ? [data['image']] : null),
      video: data['video'],
      budget: data['budget'],
      contact: data['contact'],
      textStyle: data['textStyle'],
      isBold: data['isBold'] ?? false,
    );
  }

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? data['author'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorNickname: data['authorNickname'],
      authorAvatar: data['authorAvatar'],
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      tag: data['tag'] ?? 'discussion',
      votes: (data['votes'] as num?)?.toInt() ?? 0,
      commentsCount: (data['comments'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      image: data['image'],
      images: data['images'] != null 
          ? List<String>.from(data['images']) 
          : (data['image'] != null ? [data['image']] : null),
      video: data['video'],
      budget: data['budget'],
      contact: data['contact'],
      textStyle: data['textStyle'],
      isBold: data['isBold'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorNickname': authorNickname,
      'authorAvatar': authorAvatar,
      'createdAt': Timestamp.fromDate(createdAt),
      'tag': tag,
      'votes': votes,
      'comments': commentsCount,
      'likedBy': likedBy,
      'image': image,
      if (images != null) 'images': images,
      'video': video,
      'budget': budget,
      'contact': contact,
      'textStyle': textStyle,
      'isBold': isBold,
    };
  }
}
