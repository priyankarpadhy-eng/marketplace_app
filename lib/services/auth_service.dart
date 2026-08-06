import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:truecaller_sdk/truecaller_sdk.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService._() {
    initializeTruecaller();
  }

  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '754932193228-47a6q2tnvuk52dh2p0cd834qe27594me.apps.googleusercontent.com',
  );

  void initializeTruecaller() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS);
        debugPrint('Truecaller SDK Initialized successfully');
      } catch (e) {
        debugPrint('Failed to initialize Truecaller SDK: $e');
      }
    }
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  User? get currentFirebaseUser => _auth.currentUser;

  /// PRIMARY SOURCE: Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        var role = data['role']?.toString() ?? 'founder';
        if (role == 'user' || role == 'student') {
          role = 'founder';
          await _db.collection('users').doc(user.uid).update({'role': 'founder'});
        }
        return AppUser.fromMap(doc.id, {
          ...data,
          'role': role,
          'phone_verified': true,
        });
      } else {
        return null;
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
        await _db.collection('users').doc(user.uid).update({
          'name': user.displayName ?? existingDoc.data()?['name'] ?? nickname,
          'nickname': nickname.toLowerCase().replaceAll(' ', '_'),
          'email': user.email,
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
    // 1. Update Firestore
    try {
      await _db.collection('users').doc(user.id).update(user.toMap());
      
      // 2. Sync name to listings
      await _syncUserListings(user);
    } catch (e) {
      debugPrint('Firestore profile update failed: $e');
    }
  }

  Future<void> verifyTruecaller({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    try {
      debugPrint('==== TRUECALLER: Exchanging Authorization Code ====');
      
      // 1. Exchange authorization code for access token
      final tokenResponse = await http.post(
        Uri.parse('https://oauth-account-noneu.truecaller.com/v1/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': dotenv.env['TRUECALLER_CLIENT_ID'] ?? '_vzn6lro7sbnwgvgqtgkx3lyg2uv_l6ryfd-6qdnhwm',
          'code': authorizationCode,
          'code_verifier': codeVerifier,
        },
      );
      
      debugPrint('TRUECALLER TOKEN RESPONSE [${tokenResponse.statusCode}]: ${tokenResponse.body}');
      
      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to exchange Truecaller token. Status: ${tokenResponse.statusCode}, Body: ${tokenResponse.body}');
      }
      
      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'];
      if (accessToken == null) {
        throw Exception('Access token not found in Truecaller response');
      }
      
      // 2. Fetch User Profile
      final profileResponse = await http.get(
        Uri.parse('https://oauth-account-noneu.truecaller.com/v1/userinfo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      debugPrint('TRUECALLER PROFILE RESPONSE [${profileResponse.statusCode}]: ${profileResponse.body}');
      
      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Truecaller profile. Status: ${profileResponse.statusCode}, Body: ${profileResponse.body}');
      }
      
      final profileData = jsonDecode(profileResponse.body);
      final rawPhoneNumber = profileData['phone_number'] as String?;
      if (rawPhoneNumber == null || rawPhoneNumber.isEmpty) {
        throw Exception('Phone number not found in Truecaller profile');
      }
      
      // Standardize phone number format (e.g. ensure starting with +)
      var phoneNumber = rawPhoneNumber;
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }
      
      debugPrint('TRUECALLER: Verified phone number is $phoneNumber');
      
      // 3. Update Firestore document
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _db.collection('users').doc(user.uid).update({
            'phone_number': phoneNumber,
            'phone_verified': true,
          });
        } catch (e) {
          debugPrint('[FIRESTORE ERROR] Failed to update user doc. Attempting set...: $e');
          await _db.collection('users').doc(user.uid).set({
            'phone_number': phoneNumber,
            'phone_verified': true,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('[TRUECALLER ERROR] verifyTruecaller failed: $e');
      rethrow;
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
