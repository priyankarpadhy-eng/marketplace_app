import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/campus_hub_presence.dart';

class CampusRadarService {
  static final CampusRadarService instance = CampusRadarService._internal();
  CampusRadarService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _radarCol =>
      _db.collection('campus_radar');

  /// Streams active presence list at a specific hub
  Stream<List<CampusHubPresence>> watchHubPresence(String hubId) {
    return _radarCol
        .where('hubId', isEqualTo: hubId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CampusHubPresence.fromFirestore(doc))
              .where((presence) => !presence.isExpired && presence.isActiveWithin20Mins)
              .toList()
            ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));
        });
  }

  /// Streams all active presences across all locations (active within last 20 mins)
  Stream<List<CampusHubPresence>> watchAllActivePresences() {
    return _radarCol
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CampusHubPresence.fromFirestore(doc))
              .where((presence) => !presence.isExpired && presence.isActiveWithin20Mins)
              .toList()
            ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));
        });
  }

  /// Streams current user's active check-in if any (within last 20 mins)
  Stream<CampusHubPresence?> watchUserPresence(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _radarCol.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final presence = CampusHubPresence.fromFirestore(doc);
      if (presence.isExpired ||
          !presence.isActiveWithin20Mins ||
          !(doc.data()!['active'] ?? false)) {
        return null;
      }
      return presence;
    });
  }

  /// Broadcast live location to radar with GPS coordinates
  Future<void> broadcastLocation({
    required AppUser user,
    required double latitude,
    required double longitude,
    String? customLocationName,
    int durationHours = 3,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: durationHours));
    final nearestHub = CampusHub.findNearest(latitude, longitude);
    final locName = customLocationName ?? nearestHub.name;

    final presence = CampusHubPresence(
      id: user.id,
      userId: user.id,
      userName: user.name,
      userAvatar: user.profileImage,
      userRole: user.role,
      isVerified: user.isVerified,
      verificationStatus: user.verificationStatus,
      phoneNumber: user.phoneNumber,
      hubId: nearestHub.id,
      hubName: nearestHub.name,
      latitude: latitude,
      longitude: longitude,
      locationName: locName,
      checkedInAt: now,
      expiresAt: expiresAt,
    );

    await _radarCol.doc(user.id).set(presence.toMap(), SetOptions(merge: true));
  }

  /// Check-in to a location hub (manual hub pick or GPS fallback)
  Future<void> checkIn({
    required AppUser user,
    required CampusHub hub,
    double? latitude,
    double? longitude,
    int durationHours = 3,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: durationHours));

    final presence = CampusHubPresence(
      id: user.id,
      userId: user.id,
      userName: user.name,
      userAvatar: user.profileImage,
      userRole: user.role,
      isVerified: user.isVerified,
      verificationStatus: user.verificationStatus,
      phoneNumber: user.phoneNumber,
      hubId: hub.id,
      hubName: hub.name,
      latitude: latitude ?? hub.latitude,
      longitude: longitude ?? hub.longitude,
      locationName: hub.name,
      checkedInAt: now,
      expiresAt: expiresAt,
    );

    await _radarCol.doc(user.id).set(presence.toMap(), SetOptions(merge: true));
  }

  /// Check-out / leave radar
  Future<void> checkOut(String userId) async {
    if (userId.isEmpty) return;
    await _radarCol.doc(userId).update({
      'active': false,
      'checkedOutAt': FieldValue.serverTimestamp(),
    });
  }
}
