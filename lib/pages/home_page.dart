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
      // Show blocking loading overlay
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      // First, upsert raw items so you can inspect saved data in Supabase
      final subCount = await YouTubeService.syncSubscriptionsToSupabase(
        full: full,
        maxResults: 25,
      );
      final likeCount = await YouTubeService.syncLikedVideosToSupabase(
        full: full,
        maxResults: 25,
      );
      // Then compute embeddings and assign cluster
      final embeddedCount = await YouTubeService.embedUserYouTubeProfile(
        full: full,
      );
      // After embedding, assign to a cluster (retry briefly if pending)
      Map<String, dynamic> assign = await YouTubeService.assignClusterForUser();
      if (assign['cluster_id'] == null) {
        // Retry a few times with short delays to allow eventual consistency
        for (int i = 0; i < 3 && assign['cluster_id'] == null; i++) {
          await Future.delayed(const Duration(milliseconds: 900));
          assign = await YouTubeService.assignClusterForUser();
        }
      }
      if (!mounted) return;
      setState(() {
        final cid = assign['cluster_id'];
        final sim = assign['similarity'];
        final msg = assign['message'];
        _syncInfo = cid != null
            ? 'Upserted $subCount subs, $likeCount likes • Embedded $embeddedCount • Cluster $cid (sim: ${sim?.toStringAsFixed(3) ?? sim})'
            : 'Upserted $subCount subs, $likeCount likes • Embedded $embeddedCount (cluster pending${msg != null ? ": $msg" : ""})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      // Dismiss loader if shown (avoid return in finally)
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      }
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
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
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
                // Commented out for security - user IDs should not be displayed in UI
                // signedIn ? 'User ID: $_userId' : 'Not signed in',
                signedIn ? 'Signed in' : 'Not signed in',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
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
                  if (signedIn)
                    OutlinedButton(
                      onPressed: _busy ? null : _loadSubscriptions,
                      child: const Text('Refresh list'),
                    ),
                  if (signedIn)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _syncToSupabase(full: true),
                      child: const Text('Embed + Assign'),
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
