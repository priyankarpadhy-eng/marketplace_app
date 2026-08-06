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
  @override
  UserState build() {
    _listenToAuthChanges();
    return UserState(isLoading: true);
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
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
        var role = data['role']?.toString() ?? 'founder';
        if (role == 'user' || role == 'student') {
          role = 'founder';
          FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'founder'});
        }
        state = UserState(
          currentUser: AppUser.fromMap(doc.id, {
            ...data,
            'role': role,
            'phone_verified': true,
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
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    
    final doc = await docRef.get();
    if (doc.exists) return;

    await docRef.set({
      'name': user.displayName ?? 'User',
      'nickname': user.displayName?.toLowerCase().replaceAll(' ', '_') ?? 'user_${uid.substring(0, 5)}',
      'email': user.email ?? '',
      'role': 'student',
      'gender': 'other',
      'phone_number': '',
      'phone_verified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> refreshUser() async {
    if (state.currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(state.currentUser!.id).get();
    if (doc.exists) {
      state = state.copyWith(currentUser: AppUser.fromMap(doc.id, doc.data()!));
    }
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});
