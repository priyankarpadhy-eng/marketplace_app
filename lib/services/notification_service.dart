import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../screens/main_layout.dart';
import '../screens/restaurant/restaurant_root_screen.dart';
import 'auth_service.dart';

// Mandatory top-level method for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This runs in a separate isolate when app is killed/background
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    
    // Create high importance channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('app_sound'),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleNotificationTap(details.payload);
        }
      },
    );

    // Create the channel on the device
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize FCM
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data['type'] as String?);
    });
    
    // Check initial message
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['type'] as String?);
    }
  }
  
  Future<void> _handleNotificationTap(String? type) async {
    if (type == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    final authService = AuthService.instance;
    final user = await authService.getCurrentAppUser();
    if (user == null) return;

    if (type == 'ride') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainLayout(currentUser: user, initialIndex: 1)),
        (route) => false,
      );
    } else if (type == 'listing') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainLayout(currentUser: user, initialIndex: 2)),
        (route) => false,
      );
    } else if (type == 'food_order') {
      // For Restaurants
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RestaurantRootScreen(currentUser: user)),
        (route) => false,
      );
    } else if (type == 'food_order_update') {
      // For Students
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainLayout(currentUser: user, initialIndex: 2)), // Takes them to Market where Food card is
        (route) => false,
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _notificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('app_sound'),
          ),
        ),
      );
    }
  }

  Future<String?> setupPushNotifications(String userId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the token
      String? token = await messaging.getToken();
      
      if (token != null) {
        // 3a. Save to Firestore (UX Source of Truth)
        await _db
            .collection('users')
            .doc(userId)
            .set({
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // 3c. Subscribe to global topics
        try {
          await messaging.subscribeToTopic('rides');
        } catch (e) {
          debugPrint('Topic subscription failed: $e');
        }
        
        return token;
      }
    }
    return null;
  }

  Future<void> scheduleRideReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ride_reminders',
          'Ride Reminders',
          channelDescription: 'Notifications for upcoming rides',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('app_sound'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  // --- Persistent Database Notifications ---

  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> sendNotification({
    String? userId,
    String? topic,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? image,
  }) async {
    assert(userId != null || topic != null, 'Either userId or topic must be provided');

    if (topic == 'all_users') {
      await broadcastNotification(title: title, body: body, type: type, relatedId: relatedId, image: image);
      return;
    }

    // 1. Store in Firestore for specific user
    if (userId != null) {
      await _db.collection('notifications').add({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'related_id': relatedId,
        'image': image,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Trigger direct FCM push
      try {
        final userDoc = await _db.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final fcmToken = userDoc.data()!['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await _sendDirectPushNotification(
              target: fcmToken,
              isTopic: false,
              title: title,
              body: body,
              type: type,
              relatedId: relatedId,
              image: image,
            );
          }
        }
      } catch (e) {
        debugPrint("Direct push failed: $e");
      }
    } else if (topic != null) {
      // Send to specific topic
      await _sendDirectPushNotification(
        target: topic,
        isTopic: true,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        image: image,
      );
    }
  }

  Future<void> _sendDirectPushNotification({
    required String target,
    required bool isTopic,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? image,
  }) async {
    try {
      // Load Service Account
      final serviceAccountString = await rootBundle.loadString('assets/service-account.json');
      final accountJson = jsonDecode(serviceAccountString);
      
      if (accountJson['project_id'] == 'YOUR_PROJECT_ID') {
        debugPrint("Service account is not configured.");
        return;
      }

      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountString);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final projectId = accountJson['project_id'];

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
      
      final Map<String, dynamic> payload = {
        'message': {
          if (isTopic) 'topic': target else 'token': target,
          'notification': {
            'title': title,
            'body': body,
            if (image != null && image.isNotEmpty) 'image': image,
          },
          'data': {
            'type': type,
            'related_id': relatedId ?? '',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK'
          }
        }
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        debugPrint("FCM push error: ${response.body}");
      }
      client.close();
    } catch (e) {
      debugPrint("Direct FCM send error: $e");
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'is_read': true});
  }

  Future<void> broadcastNotification({
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? image,
  }) async {
    try {
      // 1. Fetch all users
      final usersSnapshot = await _db.collection('users').get();
      if (usersSnapshot.docs.isEmpty) return;

      // 2. Prepare bulk insert
      var i = 0;
      var currentBatch = _db.batch();
      final Set<String> uniqueTokens = {};

      for (var user in usersSnapshot.docs) {
        final docRef = _db.collection('notifications').doc();
        currentBatch.set(docRef, {
          'user_id': user.id,
          'title': title,
          'body': body,
          'type': type,
          'related_id': relatedId,
          'image': image,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
        
        final fcmToken = user.data()['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          uniqueTokens.add(fcmToken);
        }

        i++;
        if (i % 500 == 0) {
          await currentBatch.commit();
          currentBatch = _db.batch();
        }
      }
      if (i % 500 != 0) {
        await currentBatch.commit();
      }

      // 3. Send direct pushes
      for (final token in uniqueTokens) {
        // Intentionally not awaiting each sequentially to speed up
        _sendDirectPushNotification(
          target: token,
          isTopic: false,
          title: title,
          body: body,
          type: type,
          relatedId: relatedId,
          image: image,
        );
      }
    } catch (e) {
      debugPrint("Broadcast Notification Error: $e");
    }
  }
}
