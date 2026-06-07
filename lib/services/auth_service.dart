import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '754932193228-47a6q2tnvuk52dh2p0cd834qe27594me.apps.googleusercontent.com',
  );

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// PRIMARY SOURCE: Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    if (user.isAnonymous) {
      return AppUser(
        id: user.uid,
        name: 'Guest User',
        email: 'guest@example.com',
        nickname: 'guest',
        role: 'guest',
        gender: 'other',
        phoneNumber: '',
        phoneVerified: false,
      );
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return AppUser.fromMap(doc.id, doc.data()!);
      } else {
        // Fallback/Create if not found
        await _createUserProfile(
          user: user,
          nickname: user.displayName ?? 'User_${user.uid.substring(0, 5)}',
        );
        return getCurrentAppUser();
      }
    } catch (e) {
      debugPrint('Error fetching user from Firestore: $e');
      return null;
    }
  }

  Future<void> _createUserProfile({
    required User user,
    required String nickname,
  }) async {
    if (user.isAnonymous) return;

    // 1. Check if profile already exists to avoid overwriting sensitive fields like 'role'
    try {
      final existingDoc = await _db.collection('users').doc(user.uid).get();
      if (existingDoc.exists) {
        // Just update some basic info like profile image or name if they changed, but NOT the role
        await _db.collection('users').doc(user.uid).update({
          'profile_image': user.photoURL,
          'updated_at': DateTime.now().toIso8601String(),
        });
        return;
      }
    } catch (e) {
      debugPrint('Error checking existing profile: $e');
    }

    final userData = {
      'name': user.displayName ?? nickname,
      'nickname': nickname.toLowerCase().replaceAll(' ', '_'),
      'email': user.email,
      'role': 'student', // Only for absolutely new users
      'gender': 'other',
      'phone_number': '',
      'phone_verified': false,
      'profile_image': user.photoURL,
      'updated_at': DateTime.now().toIso8601String(),
      'verification_status': 'none',
      'is_verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // 1. Create in Firestore
    try {
      await _db.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      debugPrint('Firestore profile creation failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _createUserProfile(
          user: user,
          nickname: user.displayName ?? 'User_${user.uid.substring(0, 5)}',
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        await _createUserProfile(
          user: user,
          nickname: nickname,
        );
      }
    } catch (e) {
      debugPrint('Email Sign-Up Error: $e');
      throw Exception('Failed to create account: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous Sign-In Error: $e');
      throw Exception('Failed to sign in as guest: $e');
    }
  }

  Future<void> signOut() async {
    // Clear FCM token before signing out to prevent receiving notifications for the old account on this device
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (_) {} // Ignore if offline or doc doesn't exist
    }
    
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> updateUserProfile(AppUser user) async {
    if (user.role == 'guest') return;
    
    // 1. Update Firestore
    try {
      await _db.collection('users').doc(user.id).update(user.toMap());
      
      // 2. Sync name to listings
      await _syncUserListings(user);
    } catch (e) {
      debugPrint('Firestore profile update failed: $e');
    }
  }

  /// Updates the seller/shop name across all user's listings for data consistency
  Future<void> _syncUserListings(AppUser user) async {
    final nameToUse = user.role == 'shop' ? (user.shopName ?? user.name) : user.name;
    
    // Update Marketplace Items
    final marketDocs = await _db.collection('marketplace').where('sellerId', isEqualTo: user.id).get();
    for (var doc in marketDocs.docs) {
      await doc.reference.update({
        'seller': nameToUse,
        'sellerName': nameToUse,
        'sellerAvatar': user.profileImage,
      });
    }

    // Update Bike Listings
    final bikeDocs = await _db.collection('bikes').where('shopId', isEqualTo: user.id).get();
    for (var doc in bikeDocs.docs) {
      await doc.reference.update({
        'shopName': nameToUse,
      });
    }
    
    // Update Rental Requests (as renter)
    final renterRequests = await _db.collection('rental_requests').where('renterId', isEqualTo: user.id).get();
    for (var doc in renterRequests.docs) {
      await doc.reference.update({
        'renterName': user.name,
      });
    }

    // Update Rental Requests (as shop owner - bikeTitle might have changed if we supported that, but here we just sync names)
    final ownerRequests = await _db.collection('rental_requests').where('shopId', isEqualTo: user.id).get();
    for (var doc in ownerRequests.docs) {
      await doc.reference.update({
        'shopName': user.shopName ?? user.name, // If we added shopName to RentalRequest model in future
      });
    }
  }
}
