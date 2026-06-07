import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  final String id;
  final String title;
  final String caption;
  final String? description;
  final String category;
  final String? bannerUrl;
  final String eventDate;
  final String? eventTime;
  final String? location;
  final String? registrationLink;
  final bool isPinned;
  final DateTime createdAt;

  EventItem({
    required this.id,
    required this.title,
    required this.caption,
    this.description,
    required this.category,
    this.bannerUrl,
    required this.eventDate,
    this.eventTime,
    this.location,
    this.registrationLink,
    this.isPinned = false,
    required this.createdAt,
  });

  factory EventItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventItem(
      id: doc.id,
      title: data['title'] ?? '',
      caption: data['caption'] ?? '',
      description: data['description'],
      category: data['category'] ?? 'general',
      bannerUrl: data['bannerUrl'],
      eventDate: data['eventDate'] ?? '',
      eventTime: data['eventTime'],
      location: data['location'],
      registrationLink: data['registrationLink'],
      isPinned: data['isPinned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'caption': caption,
      'description': description,
      'category': category,
      'bannerUrl': bannerUrl,
      'eventDate': eventDate,
      'eventTime': eventTime,
      'location': location,
      'registrationLink': registrationLink,
      'isPinned': isPinned,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
