import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initPushNotifications() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted notification permission');
      
      // 2. Get APNs Token (for iOS to verify if setup correctly)
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      log('APNs Token: $apnsToken');

      // 3. Get FCM Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        log('FCM Token: $token');
        await saveTokenToDatabase(token);
      }

      // 4. Listen to token refreshes
      _firebaseMessaging.onTokenRefresh.listen(saveTokenToDatabase);

      // 5. Setup foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Got a message whilst in the foreground!');
        log('Message data: ${message.data}');

        if (message.notification != null) {
          log('Message also contained a notification: ${message.notification}');
          // In the future you can decode the data and show an in-app banner here
        }
      });
    } else {
      log('User declined or has not accepted notification permission');
    }
  }

  Future<void> saveTokenToDatabase(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Save token as array to support multiple devices
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> removeTokenFromDatabase() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
        log('FCM Token removed successfully');
      }
    } catch (e) {
      log('Error removing FCM token: $e');
    }
  }
}
