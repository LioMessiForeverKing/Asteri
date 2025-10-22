import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'loading_page.dart';
import 'sign_in_page.dart';
import 'assignment_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkIfUserNeedsLoading(String userId) async {
    try {
      // Check if user has a successful sync recorded
      final response = await Supabase.instance.client
          .from('user_sync_status')
          .select('last_successful_sync')
          .eq('user_id', userId)
          .maybeSingle();

      // If we have a last_successful_sync, skip loading
      return (response == null || response['last_successful_sync'] == null);
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
              // User already set up -> Go to AssignmentPage
              return const AssignmentPage();
            }
          },
        );
      },
    );
  }
}
