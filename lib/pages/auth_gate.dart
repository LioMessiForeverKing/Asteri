import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'loading_page.dart';
import 'sign_in_page.dart';
import 'community_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkIfUserNeedsLoading(String userId) async {
    try {
      // Check if user has any subscriptions in the database
      final response = await Supabase.instance.client
          .from('youtube_subscriptions')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      // If no subscriptions found, user needs to go through loading
      return response.isEmpty;
    } catch (e) {
      // On error, assume loading is needed
      return true;
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

        // User is signed in -> Check if they need loading
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
              // User needs initial setup -> Show loading page
              return const LoadingPage();
            } else {
              // User already set up -> Go to communities for now (keep TimerPage for later)
              return const CommunityPage();
            }
          },
        );
      },
    );
  }
}
