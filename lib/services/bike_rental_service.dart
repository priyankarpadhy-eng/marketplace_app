import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bike_rental_model.dart';

class BikeRentalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<BikeListing>> getAvailableBikes() {
    return _db
        .collection('bikes')
        .where('isShopOpen', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map<BikeListing>((doc) => BikeListing.fromFirestore(doc)).toList());
  }

  Stream<List<BikeListing>> getShopBikes(String shopId) {
    return _db
        .collection('bikes')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map<BikeListing>((doc) => BikeListing.fromFirestore(doc)).toList());
  }

  Future<void> addBike(BikeListing bike) async {
    try {
      await _db.collection('bikes').add(bike.toMap());
    } catch (e) {
      print('Firestore add bike failed: $e');
    }
  }

  Future<void> updateBikeAvailability(String bikeId, bool isAvailable) async {
    try {
      await _db.collection('bikes').doc(bikeId).update({'isAvailable': isAvailable});
    } catch (e) {
      print('Firestore update availability failed: $e');
    }
  }

  Future<void> toggleShopStatus(String shopId, bool isOpen) async {
    try {
      final bikes = await _db.collection('bikes').where('shopId', isEqualTo: shopId).get();
      final batch = _db.batch();
      for (var doc in bikes.docs) {
        batch.update(doc.reference, {'isShopOpen': isOpen});
      }
      await batch.commit();
    } catch (e) {
      print('Firestore shop status failed: $e');
    }
  }

  Future<void> createRentalRequest(RentalRequest request) async {
    try {
      await _db.collection('rental_requests').add(request.toMap());
    } catch (e) {
      print('Firestore create request failed: $e');
    }
  }

  Stream<List<RentalRequest>> getShopRequests(String shopId) {
    return _db
        .collection('rental_requests')
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map<RentalRequest>((doc) => RentalRequest.fromFirestore(doc)).toList());
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _db.collection('rental_requests').doc(requestId).update({'status': status});
    } catch (e) {
      print('Firestore update status failed: $e');
    }
  }

  Future<void> deleteBike(String bikeId) async {
    try {
      await _db.collection('bikes').doc(bikeId).delete();
    } catch (e) {
      print('Firestore delete bike failed: $e');
    }
  }

  Future<void> updateBikeDetails(String bikeId, Map<String, dynamic> data) async {
    try {
      await _db.collection('bikes').doc(bikeId).update(data);
    } catch (e) {
      print('Firestore update bike details failed: $e');
    }
  }
}
