import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CampusHub {
  final String id;
  final String name;
  final String shortName;
  final String category; // 'transit' | 'campus' | 'junction'
  final String iconName;
  final double latitude;
  final double longitude;

  const CampusHub({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.iconName,
    required this.latitude,
    required this.longitude,
  });

  static const List<CampusHub> allHubs = [
    CampusHub(
      id: 'talcher_station',
      name: 'Talcher Railway Station',
      shortName: 'Talcher Station',
      category: 'transit',
      iconName: 'train',
      latitude: 20.9507,
      longitude: 85.2281,
    ),
    CampusHub(
      id: 'angul_station',
      name: 'Angul Railway Station',
      shortName: 'Angul Station',
      category: 'transit',
      iconName: 'train',
      latitude: 20.8443,
      longitude: 85.1011,
    ),
    CampusHub(
      id: 'campus_gate',
      name: 'IGIT Main Campus Gate',
      shortName: 'Campus Gate',
      category: 'campus',
      iconName: 'school',
      latitude: 20.9320,
      longitude: 85.2555,
    ),
    CampusHub(
      id: 'angul_bus_stand',
      name: 'Angul Central Bus Stand',
      shortName: 'Angul Bus Stand',
      category: 'transit',
      iconName: 'bus',
      latitude: 20.8385,
      longitude: 85.1054,
    ),
    CampusHub(
      id: 'banarpal',
      name: 'Banarpal Chowk / Flyover',
      shortName: 'Banarpal',
      category: 'junction',
      iconName: 'crossroads',
      latitude: 20.8710,
      longitude: 85.1610,
    ),
    CampusHub(
      id: 'talcher_thermal',
      name: 'Talcher Thermal / Hatatota',
      shortName: 'Talcher Thermal',
      category: 'junction',
      iconName: 'location',
      latitude: 20.9160,
      longitude: 85.2020,
    ),
  ];

  static CampusHub getById(String id) {
    return allHubs.firstWhere(
      (h) => h.id == id,
      orElse: () => CampusHub(
        id: id,
        name: id,
        shortName: id,
        category: 'transit',
        iconName: 'location',
        latitude: 20.9320,
        longitude: 85.2555,
      ),
    );
  }

  /// Finds closest known hub to given coordinates
  static CampusHub findNearest(double lat, double lon) {
    CampusHub nearest = allHubs.first;
    double minDistance = double.infinity;

    for (final hub in allHubs) {
      final distance = Geolocator.distanceBetween(lat, lon, hub.latitude, hub.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = hub;
      }
    }
    return nearest;
  }
}

class CampusHubPresence {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userRole;
  final bool isVerified;
  final String verificationStatus;
  final String phoneNumber;
  final String hubId;
  final String hubName;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? note;
  final String? destination;
  final DateTime checkedInAt;
  final DateTime expiresAt;

  CampusHubPresence({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.userRole,
    required this.isVerified,
    required this.verificationStatus,
    required this.phoneNumber,
    required this.hubId,
    required this.hubName,
    this.latitude,
    this.longitude,
    this.locationName,
    this.note,
    this.destination,
    required this.checkedInAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isActiveWithin20Mins =>
      DateTime.now().difference(checkedInAt).inMinutes < 20;

  String get timeAgo {
    final diff = DateTime.now().difference(checkedInAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes == 1) return '1m ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    final hours = diff.inHours;
    if (hours == 1) return '1h ago';
    return '${hours}h ago';
  }

  double? distanceInMetersFrom(double? myLat, double? myLon) {
    if (myLat == null || myLon == null || latitude == null || longitude == null) {
      return null;
    }
    return Geolocator.distanceBetween(myLat, myLon, latitude!, longitude!);
  }

  String formattedDistanceFrom(double? myLat, double? myLon) {
    final meters = distanceInMetersFrom(myLat, myLon);
    if (meters == null) return '';
    if (meters < 1000) {
      return '${meters.round()}m away';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  String get formattedCoords {
    if (latitude == null || longitude == null) return '';
    final latDir = latitude! >= 0 ? 'N' : 'S';
    final lonDir = longitude! >= 0 ? 'E' : 'W';
    return '${latitude!.abs().toStringAsFixed(4)}° $latDir, ${longitude!.abs().toStringAsFixed(4)}° $lonDir';
  }

  factory CampusHubPresence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CampusHubPresence(
      id: doc.id,
      userId: data['userId'] ?? doc.id,
      userName: data['userName'] ?? 'IGIT Student',
      userAvatar: data['userAvatar'],
      userRole: data['userRole'] ?? 'student',
      isVerified: data['isVerified'] ?? false,
      verificationStatus: data['verificationStatus'] ?? 'none',
      phoneNumber: data['phoneNumber'] ?? '',
      hubId: data['hubId'] ?? '',
      hubName: data['hubName'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationName: data['locationName'],
      note: data['note'],
      destination: data['destination'],
      checkedInAt: (data['checkedInAt'] is Timestamp)
          ? (data['checkedInAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: (data['expiresAt'] is Timestamp)
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 3)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userRole': userRole,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'phoneNumber': phoneNumber,
      'hubId': hubId,
      'hubName': hubName,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'note': note,
      'destination': destination,
      'checkedInAt': Timestamp.fromDate(checkedInAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'active': true,
    };
  }
}
