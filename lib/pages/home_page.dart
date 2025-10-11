import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<AuthState>? _authSub;
  String? _userId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    // Seed with current session's user (if already signed in)
    _userId = AuthService.currentUser?.id;

    // Listen for auth state changes
    _authSub = AuthService.authStateChanges.listen((data) {
      if (!mounted) return;
      setState(() {
        _userId = data.session?.user.id;
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);

    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await AuthService.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-out failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _userId != null;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                signedIn ? 'User ID: $_userId' : 'Not signed in',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : (signedIn ? _signOut : _signInWithGoogle),
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(signedIn ? 'Sign out' : 'Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
