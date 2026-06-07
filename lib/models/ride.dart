import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String organizerId;
  final String organizerName;
  final String organizerGender;
  final String organizerPhone;
  final bool organizerPhoneVerified;
  final String from;
  final String to;
  final DateTime departureTime;
  final String genderPreference; // 'mixed' | 'female' | 'male'
  final int totalSeats;
  final int seatsTaken;
  final String status; // 'active' | 'cancelled' | 'completed'
  final String? rideNumber; // 4-digit unique identifier

  const Ride({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.organizerGender,
    required this.organizerPhone,
    required this.organizerPhoneVerified,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.genderPreference,
    required this.totalSeats,
    required this.seatsTaken,
    required this.status,
    this.rideNumber,
  });

  factory Ride.fromMap(Map<String, dynamic> data) {
    return Ride(
      id: (data['id'] ?? '').toString(),
      organizerId: (data['organizer_id'] ?? '').toString(),
      organizerName: (data['organizer_name'] ?? 'Anonymous').toString(),
      organizerGender: (data['organizer_gender'] ?? 'mixed').toString(),
      organizerPhone: (data['organizer_phone'] ?? '').toString(),
      organizerPhoneVerified: (data['organizer_phone_verified'] as bool?) ?? false,
      from: (data['from_loc'] ?? '').toString(),
      to: (data['to_loc'] ?? '').toString(),
      departureTime: data['departure_time'] != null 
          ? DateTime.tryParse(data['departure_time'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      genderPreference: (data['gender_preference'] ?? 'mixed').toString(),
      totalSeats: (data['total_seats'] as num?)?.toInt() ?? 1,
      seatsTaken: (data['seats_taken'] as num?)?.toInt() ?? 1,
      status: (data['status'] ?? 'active').toString(),
      rideNumber: data['ride_number']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'organizer_gender': organizerGender,
      'organizer_phone': organizerPhone,
      'organizer_phone_verified': organizerPhoneVerified,
      'from_loc': from,
      'to_loc': to,
      'departure_time': departureTime.toUtc().toIso8601String(),
      'gender_preference': genderPreference,
      'total_seats': totalSeats,
      'seats_taken': seatsTaken,
      'status': status,
      'ride_number': rideNumber,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
