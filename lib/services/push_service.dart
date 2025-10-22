import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      // If Firebase failed to initialize, do not proceed; this avoids [core/no-app]
      // Ensure GoogleService-Info.plist is added to the Runner target on iOS
      // and run `pod install` in ios/ if needed.
      return;
    }

    // Request permission where needed
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Ensure notifications can show while app is in foreground (iOS)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Get and upsert token (with retry to handle iOS async registration)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final token = await _getTokenWithRetry();
      if (token != null) {
        await _upsertToken(userId: userId, token: token);
      }
    }

    // Listen for refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await _upsertToken(userId: uid, token: t);
      }
    });

    // Also listen for auth changes to register/unregister appropriately
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final t = await FirebaseMessaging.instance.getToken();
        if (t != null) await _upsertToken(userId: uid, token: t);
      } else {
        // Signed out
        await unregister();
      }
    });

    _initialized = true;
  }

  Future<String?> _getTokenWithRetry() async {
    const int maxAttempts = 10;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null && t.isNotEmpty) {
        return t;
      }
      await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
    }
    return null;
  }

  Future<void> _upsertToken({
    required String userId,
    required String token,
  }) async {
    final platform = Platform.isIOS
        ? 'ios'
        : (Platform.isAndroid ? 'android' : 'web');
    await Supabase.instance.client.from('user_push_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await Supabase.instance.client
          .from('user_push_tokens')
          .delete()
          .eq('token', token);
    }
  }
}
