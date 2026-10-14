import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/notification_service.dart';

class UserState {
  final AppUser? currentUser;
  final bool isLoading;

  UserState({this.currentUser, this.isLoading = true});

  UserState copyWith({AppUser? currentUser, bool? isLoading}) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;

  @override
  UserState build() {
    ref.onDispose(() {
      _authSubscription?.cancel();
      _profileSubscription?.cancel();
    });
    _listenToAuthChanges();
    return UserState(isLoading: true);
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToUserProfile(user.uid);
        
        // Sync push token for authenticated user
        NotificationService.instance.setupPushNotifications(user.uid);
      } else {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        state = UserState(currentUser: null, isLoading: false);
      }
    });
  }

  void _listenToUserProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        var role = data['role']?.toString() ?? 'founder';
        if (role == 'user' || role == 'student') {
          role = 'founder';
        }
        state = UserState(
          currentUser: AppUser.fromMap(doc.id, {
            ...data,
            'role': role,
            'phone_verified': (data['phone_verified'] == true) || (data['phoneVerified'] == true),
          }),
          isLoading: false,
        );
      } else {
        // Handle missing profile - auto-create minimal profile from Firebase Auth info
        _createMinimalProfile(uid);
      }
    }, onError: (error) {
      print("Error listening to user profile: $error");
      state = state.copyWith(isLoading: false);
    });
  }

  Future<void> _createMinimalProfile(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'name': user.displayName ?? 'User',
          'nickname': user.displayName?.toLowerCase().replaceAll(' ', '_') ?? 'user_${uid.substring(0, 5)}',
          'email': user.email ?? '',
          'role': 'founder',
          'gender': 'other',
          'phone_number': '',
          'phone_verified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error creating minimal profile: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = UserState(currentUser: null, isLoading: false);
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      state = state.copyWith(currentUser: AppUser.fromMap(doc.id, doc.data()!), isLoading: false);
    }
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});
