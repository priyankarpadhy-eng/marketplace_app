import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_item.dart';

class EventsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<EventItem>> watchEvents() {
    return _db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventItem.fromFirestore(doc)).toList());
  }

  Future<void> createEvent(EventItem event) async {
    await _db.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    await _db.collection('events').doc(eventId).update(data);
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }
}
