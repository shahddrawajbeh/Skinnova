import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

// Top-level handler required by Firebase for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized when this runs.
  // The OS shows the notification automatically when the app is killed/background.
}

/// Global navigator key — set this on MaterialApp so notifications can navigate.
final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  // Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'skinova_default',
    'Skinova Notifications',
    description: 'Main notification channel for Skinova',
    importance: Importance.high,
    playSound: true,
  );

  /// Call once in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    // ── 1. Register background handler ──────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // ── 2. Request permission (Android 13+ / iOS) ───────────────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // ── 3. Create Android notification channel ──────────────────────────────
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // ── 4. Initialize local notifications ──────────────────────────────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // ── 5. Foreground: show banner via flutter_local_notifications ──────────
    // setForegroundNotificationPresentationOptions is iOS-only.
    // On Android, FCM does NOT show a banner when the app is open — we do it
    // manually in onMessage using flutter_local_notifications.
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // ── 6. Handle app opened from a killed state via notification ───────────
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    // ── 7. Save FCM token to backend ────────────────────────────────────────
    await _saveToken();
    _fcm.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ── Token management ────────────────────────────────────────────────────────

  Future<void> _saveToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) return;

      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      await prefs.setString('fcmToken', token);
      await ApiService.saveFcmToken(userId, token);
    } catch (_) {}
  }

  Future<void> _onTokenRefresh(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) return;
      await prefs.setString('fcmToken', newToken);
      await ApiService.saveFcmToken(userId, newToken);
    } catch (_) {}
  }

  /// Call after login to associate the token with the newly logged-in user.
  Future<void> saveTokenForUser(String userId) async {
    print("SAVE TOKEN FUNCTION STARTED, userId = $userId");
    try {
      final token = await _fcm.getToken();
      print("FCM TOKEN = $token");

      if (token == null || token.isEmpty) {
        print("FCM TOKEN IS NULL OR EMPTY");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
      await ApiService.saveFcmToken(userId, token);
      print("TOKEN SAVED TO BACKEND SUCCESSFULLY");
    } catch (e) {
      print("FCM SAVE TOKEN ERROR = $e");
    }
  }

  /// Call on logout.
  Future<void> removeTokenOnLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final token = prefs.getString('fcmToken') ?? '';
      if (userId.isNotEmpty && token.isNotEmpty) {
        await ApiService.removeFcmToken(userId, token);
      }
      await prefs.remove('fcmToken');
    } catch (_) {}
  }

  // ── Message handlers ─────────────────────────────────────────────────────────

  /// Shows a local notification banner when the app is in the foreground.
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encodePayload(message.data),
    );
  }

  /// Called when the user taps an FCM notification (background/killed).
  void _onNotificationTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  /// Called when the user taps a local notification (foreground).
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    _navigateFromPayload(response.payload!);
  }

  // ── Navigation from notification data ────────────────────────────────────────

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final targetLink = data['targetLink'] ?? '';

    // Use a small delay so the navigator is ready (especially on cold start)
    Future.delayed(const Duration(milliseconds: 500), () {
      final nav = notificationNavigatorKey.currentState;
      if (nav == null) return;

      if (targetLink.isNotEmpty) {
        nav.pushNamed(targetLink);
        return;
      }

      switch (type) {
        case 'new_order':
        case 'order_status_changed':
          nav.pushNamed('/orders');
          break;
        case 'store_approved':
        case 'store_rejected':
        case 'new_store_request':
          nav.pushNamed('/store');
          break;
        case 'ad_approved':
        case 'ad_rejected':
        case 'new_ad_request':
          nav.pushNamed('/ads');
          break;
        case 'post_like':
        case 'post_comment':
          nav.pushNamed('/community');
          break;
        case 'new_follower':
          nav.pushNamed('/profile');
          break;
        case 'store_new_follower':
          nav.pushNamed('/store');
          break;
        case 'followed_store_new_product':
        case 'new_product':
        case 'restock':
          nav.pushNamed('/home');
          break;
        case 'review_submitted':
          nav.pushNamed('/store');
          break;
        case 'skin_scan_reminder':
          nav.pushNamed('/skin-scan');
          break;
        case 'routine_step_reminder':
          nav.pushNamed('/routine');
          break;
        case 'skincare_tip':
          nav.pushNamed('/notifications');
          break;
        case 'product_usage_reminder':
          nav.pushNamed('/profile');
          break;
        default:
          nav.pushNamed('/notifications');
      }
    });
  }

  void _navigateFromPayload(String payload) {
    try {
      final parts = payload.split('&');
      final map = <String, dynamic>{};
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2) map[kv[0]] = Uri.decodeComponent(kv[1]);
      }
      _navigateFromData(map);
    } catch (_) {}
  }

  String _encodePayload(Map<String, dynamic> data) => data.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
      .join('&');
}
