import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/post.dart';
import '../models/marketplace_item.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER MANAGEMENT ---

  Stream<List<AppUser>> watchAllUsers() {
    return _db
        .collection('users')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList());
  }

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    // Firestore does not have native ilike search. A basic prefix search or client-side filtering can be used.
    // For admin tool, we can fetch all or a large chunk and filter if the DB is small, 
    // or use a prefix search on name.
    final q = query.toLowerCase();
    final snapshot = await _db.collection('users').get();
    
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .where((user) => 
            (user.name.toLowerCase().contains(q)) || 
            (user.email.toLowerCase().contains(q)))
        .take(20)
        .toList();
  }

  Future<AppUser?> searchUserByEmail(String email) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return AppUser.fromMap(doc.id, doc.data());
    }
    return null;
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    return await _db.collection('users').doc(uid).update({'role': newRole});
  }

  // --- SHOP VERIFICATION ---

  Stream<List<AppUser>> watchPendingVerifications() {
    return _db
        .collection('users')
        .where('verification_status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> updateVerificationStatus(String uid, {required bool isVerified, required String status}) async {
    await _db.collection('users').doc(uid).update({
      'is_verified': isVerified,
      'verification_status': status,
    });

    // Sync to separate collections
    await _db.collection('shop_verifications').doc(uid).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('shops').doc(uid).set({
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveShop(String uid, List<String> tags) async {
    final updateData = {
      'role': 'shop',
      'is_verified': true,
      'verification_status': 'approved',
      'shop_tags': tags,
    };
    await _db.collection('users').doc(uid).update(updateData);

    // Update shops collection
    await _db.collection('shops').doc(uid).set({
      'userId': uid,
      'isVerified': true,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update shop_verifications status
    await _db.collection('shop_verifications').doc(uid).set({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  // --- CONTENT MODERATION ---

  Stream<List<Post>> watchAllPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<MarketplaceItem>> watchAllListings() {
    return _db
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MarketplaceItem.fromFirestore(doc)).toList());
  }

  Future<void> deletePost(String postId) async {
    return await _db.collection('posts').doc(postId).delete();
  }

  Future<void> deleteListing(String listingId) async {
    return await _db.collection('listings').doc(listingId).delete();
  }

  Stream<Map<String, int>> watchDashboardStats() async* {
    while (true) {
      try {
        final usersCount = await _db.collection('users').count().get();
        final listingsCount = await _db.collection('listings').count().get();
        final postsCount = await _db.collection('posts').count().get();
        final pendingCount = await _db.collection('users').where('verification_status', isEqualTo: 'pending').count().get();
        
        yield {
          'users': usersCount.count ?? 0,
          'listings': listingsCount.count ?? 0,
          'posts': postsCount.count ?? 0,
          'pending': pendingCount.count ?? 0,
        };
      } catch (e) {
        debugPrint('Error fetching dashboard stats: $e');
        yield {'users': 0, 'listings': 0, 'posts': 0, 'pending': 0};
      }
      
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Stream<QuerySnapshot> watchReports() {
    return _db.collection('reports').orderBy('createdAt', descending: true).snapshots();
  }
}
