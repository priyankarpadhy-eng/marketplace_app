import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feature_request.dart';

class FeatureRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FeatureRequest>> watchRequests() {
    return _db
        .collection('featureRequests')
        .orderBy('votes', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FeatureRequest.fromFirestore(doc)).toList());
  }

  Future<void> submitRequest(FeatureRequest request) async {
    await _db.collection('featureRequests').add(request.toMap());
  }

  Future<void> voteRequest(String requestId, String userId) async {
    final docRef = _db.collection('featureRequests').doc(requestId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final List<String> voterIds = List<String>.from(data['voterIds'] ?? []);
      final bool hasVoted = voterIds.contains(userId);

      if (hasVoted) {
        transaction.update(docRef, {
          'votes': FieldValue.increment(-1),
          'voterIds': FieldValue.arrayRemove([userId]),
        });
      } else {
        transaction.update(docRef, {
          'votes': FieldValue.increment(1),
          'voterIds': FieldValue.arrayUnion([userId]),
        });
      }
    });
  }
}
