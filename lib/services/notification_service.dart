import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/order_tracking_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<String>? _tokenSubscription;

  /// Prompts notification permission (Android 13+ / iOS) right after login
  /// or registration, and saves the device's FCM token to /users/{uid}.
  Future<void> requestPermissionAndSaveToken(String uid) async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _fcm.getToken();
        if (token != null) {
          await _db.collection('users').doc(uid).set(
            {'fcm_token': token},
            SetOptions(merge: true),
          );
        }

        // Listen for token rotations and keep user document updated
        _tokenSubscription?.cancel();
        _tokenSubscription = _fcm.onTokenRefresh.listen((newToken) {
          _db.collection('users').doc(uid).set(
            {'fcm_token': newToken},
            SetOptions(merge: true),
          );
        });
      }
    } catch (e) {
      debugPrint('Error setting up push notifications: $e');
    }
  }

  /// Sets up foreground, background, and terminated app notification tap handlers.
  void initializeListeners(BuildContext context) {
    // 1. Foreground message handler (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? 'Order Status Update',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notification.body ?? ''),
              ],
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: message.data['order_id'] != null
                ? SnackBarAction(
                    label: 'VIEW',
                    onPressed: () {
                      final orderId = message.data['order_id'];
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(orderId: orderId),
                          ),
                        );
                      }
                    },
                  )
                : null,
          ),
        );
      }
    });

    // 2. Background notification tap handler (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (context.mounted) {
        _handleNotificationTap(context, message);
      }
    });

    // 3. Terminated app notification tap handler (app was completely closed)
    _checkInitialMessage(context);
  }

  Future<void> _checkInitialMessage(BuildContext context) async {
    final message = await _fcm.getInitialMessage();
    if (!context.mounted) return;
    if (message != null) {
      _handleNotificationTap(context, message);
    }
  }

  void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    if (!context.mounted) return;
    final orderId = message.data['order_id'];
    if (orderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        ),
      );
    }
  }

  void dispose() {
    _tokenSubscription?.cancel();
  }
}
