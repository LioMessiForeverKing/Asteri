import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;
  
  // Get auth state stream
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Sign in with Google
  static Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: _platformClientId(),
      serverClientId: AppConstants.kGoogleWebClientId,
    );

    final user = await googleSignIn.signIn();
    if (user == null) {
      throw const AuthException('User cancelled sign in.');
    }

    final auth = await user.authentication;
    final accessToken = auth.accessToken;
    final idToken = auth.idToken;

    if (idToken == null) {
      throw const AuthException('Google did not return an ID token.');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
  
  // Sign out
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Get platform-specific client ID
  static String? _platformClientId() {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return AppConstants.kGoogleIosClientId;
      case TargetPlatform.android:
        return null;
      default:
        return null;
    }
  }
}
