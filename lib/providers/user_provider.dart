import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/notification_service.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  UserProvider() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      } else if (user.isAnonymous) {
        _currentUser = AppUser(
          id: user.uid,
          name: 'Guest User',
          email: 'guest@example.com',
          nickname: 'guest',
          role: 'guest',
          gender: 'other',
          phoneNumber: '',
          phoneVerified: false,
        );
        _isLoading = false;
        notifyListeners();
        
        // Sync push token for guest
        NotificationService.instance.setupPushNotifications(user.uid);
      } else {
        _listenToUserProfile(user.uid);
        
        // Sync push token for authenticated user
        NotificationService.instance.setupPushNotifications(user.uid);
      }
    });
  }

  void _listenToUserProfile(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        if (data['role'] == 'user') {
          // Auto-upgrade legacy role to pass Firestore rules
          FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'student'});
        }
        _currentUser = AppUser.fromMap(doc.id, data);
      } else {
        // Handle missing profile - auto-create minimal profile from Firebase Auth info
        _createMinimalProfile(uid);
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print("Error listening to user profile: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _createMinimalProfile(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    
    // Check again to avoid race conditions
    final doc = await docRef.get();
    if (doc.exists) return;

    await docRef.set({
      'name': user.displayName ?? user.email?.split('@').first ?? 'User',
      'nickname': user.displayName ?? user.email?.split('@').first ?? 'user',
      'email': user.email,
      'role': 'student',
      'gender': 'other',
      'phoneNumber': user.phoneNumber ?? '',
      'phoneVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.id).get();
    if (doc.exists) {
      _currentUser = AppUser.fromMap(doc.id, doc.data()!);
      notifyListeners();
    }
  }
}
