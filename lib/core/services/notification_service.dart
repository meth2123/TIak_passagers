import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  late final FirebaseMessaging _firebaseMessaging;
  late String? _fcmToken;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // Request user permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup on message opened from terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    debugPrint('Message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // TODO: Navigate based on message type
    // TODO: Update app state via Riverpod
  }

  String? get fcmToken => _fcmToken;

  /// Refresh FCM token (should be called periodically)
  Future<void> refreshToken() async {
    _fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token refreshed: $_fcmToken');
  }
}

/// Background message handler (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

