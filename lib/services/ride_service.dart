import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For compute
import 'notification_service.dart';
import '../models/app_user.dart';
import '../models/ride.dart';

class RideService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static List<Ride>? _cachedRides; // Persistent cache for this session

  Stream<List<Ride>> watchAllRides() async* {
    if (_cachedRides != null) {
      yield _cachedRides!;
    }

    try {
      final initialSnapshot = await _db
          .collection('rides')
          .get();
          
      final rides = _processRideData(initialSnapshot.docs);
      _cachedRides = rides;
      yield rides;
    } catch (e) {
      debugPrint("Initial ride fetch failed: $e");
    }

    final stream = _db
        .collection('rides')
        .snapshots();

    await for (final snapshot in stream) {
      final rides = await compute(_processRideDataIsolate, snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
      _cachedRides = rides;
      yield rides;
    }
  }

  static List<Ride>? get cachedRides => _cachedRides;

  List<Ride> _processRideData(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return _processRideDataIsolate(docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  static List<Ride> _processRideDataIsolate(List<Map<String, dynamic>> data) {
    final rides = data.map((map) => Ride.fromMap(map)).toList();
    rides.sort((a, b) => b.departureTime.compareTo(a.departureTime));
    return rides;
  }

  Future<void> sendSystemMessage({
    required String rideId,
    required String text,
  }) async {
    await _db.collection('ride_messages').add({
      'ride_id': rideId,
      'sender_id': 'SYSTEM',
      'sender_name': 'System',
      'text': text,
      'sent_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Ride> createRide({
    required AppUser organizer,
    required String from,
    required String to,
    required DateTime departureTime,
    required String genderPreference,
    required int totalSeats,
    String? customPhone,
  }) async {
    final rideNumber = (Random().nextInt(9000) + 1000).toString();
    
    final rideData = {
      'organizer_id': organizer.id,
      'organizer_name': organizer.name,
      'organizer_gender': organizer.gender,
      'organizer_phone': customPhone ?? organizer.phoneNumber,
      'organizer_phone_verified': organizer.phoneVerified,
      'from_loc': from,
      'to_loc': to,
      'departure_time': departureTime.toUtc().toIso8601String(),
      'gender_preference': genderPreference,
      'total_seats': totalSeats.clamp(1, 6),
      'seats_taken': 1,
      'status': 'active',
      'ride_number': rideNumber,
      'created_at': FieldValue.serverTimestamp(),
    };

    final docRef = await _db.collection('rides').add(rideData);
    final rideId = docRef.id;

    await _db.collection('ride_participants').add({
      'ride_id': rideId,
      'user_id': organizer.id,
      'user_name': organizer.name,
      'user_gender': organizer.gender,
      'user_phone': customPhone ?? organizer.phoneNumber,
      'user_phone_verified': organizer.phoneVerified,
      'role': 'organizer',
      'joined_at': FieldValue.serverTimestamp(),
    });

    await sendSystemMessage(rideId: rideId, text: "${organizer.name} created the ride.");

    await NotificationService.instance.sendNotification(
      userId: organizer.id,
      title: 'Ride Created! 🚗',
      body: 'Your ride from $from to $to is now live.',
      type: 'ride',
      relatedId: rideId,
    );

    await NotificationService.instance.scheduleRideReminder(
      id: rideId.hashCode,
      title: 'Ride Departure Reminder',
      body: 'Your ride from $from to $to starts in 15 minutes!',
      scheduledDate: departureTime.subtract(const Duration(minutes: 15)),
    );

    final formattedTime = "${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}";
    final formattedDate = "${departureTime.day}/${departureTime.month}";
    await NotificationService.instance.broadcastNotification(
      title: 'New Ride Alert! 🚗',
      body: 'New trip from $from to $to on $formattedDate at $formattedTime. Tap to join!',
      type: 'ride',
      relatedId: rideId,
    );

    return Ride.fromMap({'id': rideId, ...rideData});
  }

  Future<void> joinRide({
    required Ride ride,
    required AppUser user,
  }) async {
    final rideDocRef = _db.collection('rides').doc(ride.id);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideDocRef);
      if (!snapshot.exists) throw Exception('Ride does not exist');
      
      final data = snapshot.data()!;
      if (data['status'] != 'active') throw Exception('Ride is not active');
      
      final totalSeats = (data['total_seats'] as num).toInt();
      final currentSeatsTaken = (data['seats_taken'] as num).toInt();
      
      if (currentSeatsTaken >= totalSeats) throw Exception('Ride is full');

      transaction.update(rideDocRef, {
        'seats_taken': currentSeatsTaken + 1,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    await _db.collection('ride_participants').add({
      'ride_id': ride.id,
      'user_id': user.id,
      'user_name': user.name,
      'user_gender': user.gender,
      'user_phone': user.phoneNumber,
      'user_phone_verified': user.phoneVerified,
      'role': 'participant',
      'joined_at': FieldValue.serverTimestamp(),
    });

    await sendSystemMessage(rideId: ride.id, text: "${user.name} joined the ride.");

    await NotificationService.instance.sendNotification(
      userId: user.id,
      title: 'Ride Joined! ✅',
      body: 'You successfully joined the ride from ${ride.from} to ${ride.to}.',
      type: 'ride',
      relatedId: ride.id,
    );

    final participantRecords = await _db
        .collection('ride_participants')
        .where('ride_id', isEqualTo: ride.id)
        .get();

    for (final doc in participantRecords.docs) {
      final participantId = doc.data()['user_id'] as String;
      if (participantId == user.id) continue;

      await NotificationService.instance.sendNotification(
        userId: participantId,
        title: 'New Rider Joined! 🚗',
        body: '${user.name} has joined the ride from ${ride.from} to ${ride.to}.',
        type: 'ride',
        relatedId: ride.id,
      );
    }

    await NotificationService.instance.scheduleRideReminder(
      id: ride.id.hashCode,
      title: 'Ride Departure Reminder',
      body: 'Your ride from ${ride.from} to ${ride.to} starts in 15 minutes!',
      scheduledDate: ride.departureTime.subtract(const Duration(minutes: 15)),
    );
  }

  Future<void> leaveRide({
    required Ride ride,
    required AppUser user,
  }) async {
    final participantsQuery = await _db
        .collection('ride_participants')
        .where('ride_id', isEqualTo: ride.id)
        .where('user_id', isEqualTo: user.id)
        .limit(1)
        .get();

    if (participantsQuery.docs.isEmpty) return;
    
    final participantDoc = participantsQuery.docs.first;
    if (participantDoc.data()['role'] == 'organizer') throw Exception('Organizer must cancel instead');

    final rideDocRef = _db.collection('rides').doc(ride.id);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideDocRef);
      if (!snapshot.exists) return;
      
      final seatsTaken = (snapshot.data()!['seats_taken'] as num).toInt();

      transaction.delete(participantDoc.reference);
      transaction.update(rideDocRef, {
        'seats_taken': seatsTaken - 1,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    await sendSystemMessage(rideId: ride.id, text: "${user.name} left the ride.");
    await NotificationService.instance.cancelNotification(ride.id.hashCode);
  }

  Future<void> kickParticipant({
    required String rideId,
    required String userId,
    required String userName,
  }) async {
    final participantsQuery = await _db
        .collection('ride_participants')
        .where('ride_id', isEqualTo: rideId)
        .where('user_id', isEqualTo: userId)
        .where('role', isEqualTo: 'participant')
        .limit(1)
        .get();

    if (participantsQuery.docs.isEmpty) return;

    final rideDocRef = _db.collection('rides').doc(rideId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideDocRef);
      if (!snapshot.exists) return;
      
      final seatsTaken = (snapshot.data()!['seats_taken'] as num).toInt();

      transaction.delete(participantsQuery.docs.first.reference);
      transaction.update(rideDocRef, {
        'seats_taken': seatsTaken - 1,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });

    await sendSystemMessage(rideId: rideId, text: "$userName was removed from the ride by the organizer.");
    await NotificationService.instance.cancelNotification(rideId.hashCode);
  }

  Future<void> cancelRide(Ride ride) async {
    final participantsSnapshot = await _db
        .collection('ride_participants')
        .where('ride_id', isEqualTo: ride.id)
        .get();

    await _db.collection('rides').doc(ride.id).update({
      'status': 'cancelled',
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    await sendSystemMessage(rideId: ride.id, text: "The ride has been cancelled by the organizer.");

    for (var doc in participantsSnapshot.docs) {
      final userId = doc.data()['user_id'] as String;
      if (userId == ride.organizerId) continue;

      await NotificationService.instance.sendNotification(
        userId: userId,
        title: 'Ride Cancelled ⚠️',
        body: 'The ride from ${ride.from} to ${ride.to} has been cancelled.',
        type: 'ride',
        relatedId: ride.id,
      );
    }

    await NotificationService.instance.cancelNotification(ride.id.hashCode);
  }

  Stream<List<Map<String, dynamic>>> watchParticipants(String rideId) {
    return _db
        .collection('ride_participants')
        .where('ride_id', isEqualTo: rideId)
        .snapshots()
        .map((snapshot) {
          final participants = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          participants.sort((a, b) {
            final aTime = (a['joined_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['joined_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            return aTime.compareTo(bTime);
          });
          return participants;
        });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String rideId) {
    return _db
        .collection('ride_messages')
        .where('ride_id', isEqualTo: rideId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          messages.sort((a, b) {
            final aTime = (a['sent_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['sent_at'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime); // Descending
          });
          return messages;
        });
  }

  Future<void> sendMessage({
    required String rideId,
    required AppUser sender,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await _db.collection('ride_messages').add({
      'ride_id': rideId,
      'sender_id': sender.id,
      'sender_name': sender.name,
      'text': text.trim(),
      'sent_at': FieldValue.serverTimestamp(),
    });

    final participantsSnapshot = await _db
        .collection('ride_participants')
        .where('ride_id', isEqualTo: rideId)
        .get();

    for (var doc in participantsSnapshot.docs) {
      final userId = doc.data()['user_id'] as String;
      
      if (userId == sender.id) continue;

      await NotificationService.instance.sendNotification(
        userId: userId,
        title: 'New Message from ${sender.name} 💬',
        body: text.trim(),
        type: 'ride_message',
        relatedId: rideId,
      );
    }
  }

  Future<Ride?> getRideById(String rideId) async {
    try {
      final doc = await _db.collection('rides').doc(rideId).get();
      if (!doc.exists) return null;
      return Ride.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      print('Error fetching ride by ID: $e');
      return null;
    }
  }
}
