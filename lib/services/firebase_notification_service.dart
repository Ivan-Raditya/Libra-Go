import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      
      final firebaseMessaging = FirebaseMessaging.instance;
      
      // Request permission
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted permission for notifications');
        }
        
        // Get FCM token
        String? token = await firebaseMessaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        
        // Handle incoming messages while app is in foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Received foreground message: ${message.notification?.title}');
          }
          // Normally you'd show a local notification here using flutter_local_notifications
        });

      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed (probably missing google-services.json): $e');
      }
    }
  }
}
