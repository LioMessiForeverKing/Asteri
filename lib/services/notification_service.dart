import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../main.dart';
import '../pages/messages_page.dart';
import '../pages/star_map_page.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _messagesChannelId = 'messages';
  static const String _messagesChannelName = 'Messages';
  static const String _messagesChannelDescription = 'Notifications for new messages';

  static const String _friendRequestsChannelId = 'friend_requests';
  static const String _friendRequestsChannelName = 'Friend Requests';
  static const String _friendRequestsChannelDescription = 'Notifications for friend requests';

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Configure Firebase messaging for background/terminated state
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _initialized = true;
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _messagesChannelId,
          _messagesChannelName,
          description: _messagesChannelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _friendRequestsChannelId,
          _friendRequestsChannelName,
          description: _friendRequestsChannelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      );
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Handle foreground messages - show local notification
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: data.toString(),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    // Handle when user taps notification from background/terminated state
    _handleNotificationPayload(message.data);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle when user taps local notification
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        // Parse the payload - for now we'll use simple string matching
        _handleNotificationPayload({'payload': payload});
      } catch (e) {
        // Handle parsing error
      }
    }
  }

  void _handleNotificationPayload(Map<String, dynamic> data) {
    final type = data['type'];

    // Use navigator key to navigate to appropriate screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        if (type == 'message') {
          // Navigate to messages page - push on top of current navigation
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => const MessagesPage()),
          );
        } else if (type == 'friend_request') {
          // Navigate to star map - push on top of current navigation
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => const StarMapPage()),
          );
        }
      }
    });
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String messagePreview,
    String? conversationId,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New message from $senderName',
      body: messagePreview,
      payload: 'type=message&conversationId=$conversationId',
    );
  }

  Future<void> showFriendRequestNotification({
    required String senderName,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Friend request',
      body: '$senderName sent you a friend request',
      payload: 'type=friend_request',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
