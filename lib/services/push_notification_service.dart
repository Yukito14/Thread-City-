import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../repositories/message_repository.dart';

class PushNotificationService {
  PushNotificationService(this._messageRepository);

  final MessageRepository _messageRepository;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static bool _isLocalNotificationInitialized = false;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<String>? _tokenRefreshSub;

  static const AndroidNotificationChannel _chatChannel =
  AndroidNotificationChannel(
    'chat_messages',
    'Tin nhắn',
    description: 'Thông báo tin nhắn mới',
    importance: Importance.high,
  );

  Future<void> init({
    required String firebaseUid,
  }) async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveCurrentToken(firebaseUid);
    _listenTokenRefresh(firebaseUid);
    _listenForegroundMessages();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('[FCM] 🔔 Permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    if (_isLocalNotificationInitialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('[FCM] 👆 Notification clicked: ${response.payload}');
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);

    _isLocalNotificationInitialized = true;
  }

  Future<void> _saveCurrentToken(String firebaseUid) async {
    try {
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        print('[FCM] ⚠️ Token null');
        return;
      }

      print('[FCM] ✅ Token: $token');

      await _messageRepository.saveFcmToken(
        firebaseUid: firebaseUid,
        fcmToken: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
      );

      print('[FCM] ✅ Token saved to backend');
    } catch (e) {
      print('[FCM] ❌ Save token error: $e');
    }
  }

  void _listenTokenRefresh(String firebaseUid) {
    _tokenRefreshSub?.cancel();

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      try {
        print('[FCM] 🔄 Token refreshed: $newToken');

        await _messageRepository.saveFcmToken(
          firebaseUid: firebaseUid,
          fcmToken: newToken,
          platform: Platform.isAndroid ? 'android' : 'ios',
        );

        print('[FCM] ✅ Refreshed token saved');
      } catch (e) {
        print('[FCM] ❌ Save refreshed token error: $e');
      }
    });
  }

  void _listenForegroundMessages() {
    _foregroundSub?.cancel();

    _foregroundSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('[FCM] 📩 Foreground message: ${message.data}');

      final notification = message.notification;

      final title = notification?.title ?? 'Tin nhắn mới';
      final body = notification?.body ?? 'Bạn có tin nhắn mới';

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannel.id,
            _chatChannel.name,
            channelDescription: _chatChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    });
  }

  static Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenRefreshSub?.cancel();

    _foregroundSub = null;
    _tokenRefreshSub = null;
  }
}