import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const List<String> _scopes = <String>[
    'email',
    'profile',
    'https://www.googleapis.com/auth/youtube.readonly',
  ];

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Get auth state stream
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // Sign in with Google
  static Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: _platformClientId(),
      serverClientId: AppConstants.kGoogleWebClientId,
      scopes: _scopes,
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

  // Attempt silent Google sign-in and ensure Supabase session exists.
  // If a Google account is available, link it to Supabase without UI.
  static Future<void> signInSilentlyAndLinkSupabase() async {
    final googleSignIn = GoogleSignIn(
      clientId: _platformClientId(),
      serverClientId: AppConstants.kGoogleWebClientId,
      scopes: _scopes,
    );

    // If already signed in to Supabase, nothing to do here.
    if (_supabase.auth.currentUser != null) {
      return;
    }

    GoogleSignInAccount? user = googleSignIn.currentUser;
    user ??= await googleSignIn.signInSilently();
    if (user == null) return;

    final auth = await user.authentication;
    final accessToken = auth.accessToken;
    final idToken = auth.idToken;
    if (idToken == null) return;

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // Retrieve Google OAuth access token (with YouTube scope) for API calls
  static Future<String?> getGoogleAccessToken() async {
    final googleSignIn = GoogleSignIn(
      clientId: _platformClientId(),
      serverClientId: AppConstants.kGoogleWebClientId,
      scopes: _scopes,
    );
    GoogleSignInAccount? user = googleSignIn.currentUser;
    user ??= await googleSignIn.signInSilently();
    if (user == null) return null;
    final auth = await user.authentication;
    return auth.accessToken;
  }

  // Sign out
  static Future<void> signOut() async {
    // Also sign out of Google to avoid silent auto re-link on next launch
    final googleSignIn = GoogleSignIn(
      clientId: _platformClientId(),
      serverClientId: AppConstants.kGoogleWebClientId,
      scopes: _scopes,
    );
    await googleSignIn.signOut();
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
