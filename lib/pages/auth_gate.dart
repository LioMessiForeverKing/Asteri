import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'loading_page.dart';
import 'sign_in_page.dart';
import 'root_nav_page.dart';
import '../services/profile_service.dart';
import 'profile_setup_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkIfUserNeedsLoading(String userId) async {
    try {
      final client = Supabase.instance.client;

      // Check explicit embeddings presence (more reliable than timestamp alone)
      final embedding = await client
          .from('user_embeddings')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (embedding == null) {
        return true; // No embeddings → needs loading
      }

      // Fallback: also consider sync timestamp if embeddings row exists but is stale
      final sync = await client
          .from('user_sync_status')
          .select('last_successful_sync')
          .eq('user_id', userId)
          .maybeSingle();

      return (sync == null || sync['last_successful_sync'] == null);
    } catch (e) {
      // On error, default to skip loading to avoid re-running heavy pipeline
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session == null) {
          // User not signed in -> Show sign in page
          return const SignInPage();
        }

        // User is signed in -> First, ensure initial data load if needed
        return FutureBuilder<bool>(
          future: _checkIfUserNeedsLoading(session.user.id),
          builder: (context, loadingSnapshot) {
            if (loadingSnapshot.connectionState == ConnectionState.waiting) {
              // Still checking, show a simple loading indicator
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final needsLoading = loadingSnapshot.data ?? true;
            if (needsLoading) {
              return const LoadingPage();
            }

            // After loading is satisfied, ensure profile completion
            return FutureBuilder<bool>(
              future: ProfileService.isProfileComplete(session.user.id),
              builder: (context, profileSnap) {
                if (profileSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final isProfileComplete = profileSnap.data ?? false;
                if (!isProfileComplete) {
                  return const ProfileSetupPage();
                }
                return const RootNavPage();
              },
            );
          },
        );
      },
    );
  }
}
