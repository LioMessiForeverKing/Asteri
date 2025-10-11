import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/youtube_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<AuthState>? _authSub;
  String? _userId;
  bool _busy = false;
  List<Map<String, dynamic>> _subscriptions = <Map<String, dynamic>>[];
  String? _error;
  String? _syncInfo;

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
      if (data.session?.user.id != null) {
        _loadSubscriptions();
        _syncToSupabase();
      } else {
        setState(() {
          _subscriptions = <Map<String, dynamic>>[];
          _error = null;
          _syncInfo = null;
        });
      }
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
      await _loadSubscriptions();
      await _syncToSupabase();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-out failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncToSupabase({bool full = true}) async {
    try {
      final subCount = await YouTubeService.syncSubscriptionsToSupabase(
        full: full,
        maxResults: 25,
      );
      final likeCount = await YouTubeService.syncLikedVideosToSupabase(
        full: full,
        maxResults: 25,
      );
      if (!mounted) return;
      setState(() {
        _syncInfo = 'Synced $subCount subs, $likeCount liked videos';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await YouTubeService.fetchMySubscriptions(maxResults: 15);
      if (!mounted) return;
      setState(() {
        _subscriptions = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _userId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                signedIn ? 'User ID: $_userId' : 'Not signed in',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : (signedIn ? _signOut : _signInWithGoogle),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(signedIn ? 'Sign out' : 'Sign in with Google'),
                  ),
                  const SizedBox(width: 8),
                  if (signedIn)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _busy ? null : _loadSubscriptions,
                          child: const Text('Refresh list'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _syncToSupabase(full: true),
                          child: const Text('Full sync to Supabase'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_syncInfo != null)
                Text(_syncInfo!, textAlign: TextAlign.center),
              if (signedIn)
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _subscriptions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _subscriptions[index];
                      final snippet =
                          (item['snippet'] ?? {}) as Map<String, dynamic>;
                      final title = snippet['title']?.toString() ?? 'Untitled';
                      final description =
                          snippet['description']?.toString() ?? '';
                      final thumbnails =
                          (snippet['thumbnails'] ?? {}) as Map<String, dynamic>;
                      final defaultThumb =
                          (thumbnails['default'] ?? {}) as Map<String, dynamic>;
                      final thumbUrl = defaultThumb['url']?.toString();
                      return ListTile(
                        leading: thumbUrl != null
                            ? Image.network(
                                thumbUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(width: 40, height: 40),
                        title: Text(title),
                        subtitle: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
