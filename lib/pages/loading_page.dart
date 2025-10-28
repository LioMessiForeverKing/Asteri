import 'dart:async';
import 'package:flutter/material.dart';
// removed svg loader in favor of hourglass
import '../services/youtube_service.dart';
import '../services/openai_service.dart';
import '../models/passion_graph.dart';
import '../widgets/asteria_loading_animation.dart';
import 'dart:math' as math;
import '../theme.dart';
import 'root_nav_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  String _statusMessage = 'Initializing...';
  bool _showContinue = false;

  // Animation values
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controllers
    _fadeController = AnimationController(
      duration: AsteriaTheme.animationMedium,
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: AsteriaTheme.curveElegant,
      ),
    );

    // Start animations
    _fadeController.forward();

    // Start the data processing
    _startProcessing();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    try {
      // Step 1: Sync subscriptions
      setState(() {
        _statusMessage = 'Mapping your digital footprint...';
      });

      await YouTubeService.syncSubscriptionsToSupabase(
        full: true,
        maxResults: 50,
      );

      if (!mounted) return;

      // Step 2: Sync liked videos
      setState(() {
        _statusMessage = 'Analyzing your social graph...';
      });

      await YouTubeService.syncLikedVideosToSupabase(
        full: true,
        maxResults: 50,
      );

      if (!mounted) return;

      // Step 3: Create embeddings
      setState(() {
        _statusMessage = 'Discovering your connection patterns...';
      });

      await YouTubeService.embedUserYouTubeProfile(full: true);

      if (!mounted) return;

      // Step 4: Assign cluster
      setState(() {
        _statusMessage = 'Finding your tribe...';
      });

      Map<String, dynamic> assign = await YouTubeService.assignClusterForUser();

      // Retry logic for cluster assignment
      if (assign['cluster_id'] == null) {
        for (int i = 0; i < 5 && assign['cluster_id'] == null; i++) {
          await Future.delayed(const Duration(milliseconds: 800));
          assign = await YouTubeService.assignClusterForUser();
        }
      }

      if (!mounted) return;

      // Step 5: Summarize passions via OpenAI and prepare graph
      setState(() {
        _statusMessage = 'Composing your knowledge map...';
      });

      final subs = await YouTubeService.fetchAllSubscriptions(pageSize: 50);
      final likes = await YouTubeService.fetchAllLikedVideos(
        pageSize: 50,
        maxItems: 100,
      );
      GraphSnapshot snapshot = await OpenAIService.summarizePassions(
        subscriptions: subs,
        likedVideos: likes,
      );

      // Deduplicate nodes/edges before layout
      snapshot = _dedupeGraph(snapshot);

      // Seed initial circular layout
      final int n = snapshot.nodes.length;
      for (int i = 0; i < n; i++) {
        final double angle = (i / n) * 6.28318530718; // 2*pi
        snapshot.nodes[i].x = 140 * math.cos(angle);
        snapshot.nodes[i].y = 140 * math.sin(angle);
      }

      setState(() {
        _statusMessage = 'Almost ready...';
      });

      // Step 6: Complete
      setState(() {
        _statusMessage = 'All set!';
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Mark user as successfully set up
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Supabase.instance.client.from('user_sync_status').upsert({
            'user_id': userId,
            'last_successful_sync': DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {
        // Non-fatal: continue navigation
      }

      // Navigate into app shell with bottom navigation
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const RootNavPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: AsteriaTheme.animationMedium,
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _showContinue = true;
      });
    }
  }

  void _navigateToStarMap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RootNavPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AsteriaTheme.animationMedium,
      ),
    );
  }

  GraphSnapshot _dedupeGraph(GraphSnapshot snapshot) {
    final Map<String, PassionNode> byLabel = <String, PassionNode>{};
    for (final node in snapshot.nodes) {
      final String key = node.label.trim().toLowerCase();
      final PassionNode? existing = byLabel[key];
      if (existing == null || node.weight > existing.weight) {
        byLabel[key] = node;
      }
    }
    final List<PassionNode> nodes = byLabel.values.toList();
    final Set<String> validIds = nodes.map((n) => n.id).toSet();
    final List<GraphEdge> edges = snapshot.edges
        .where(
          (e) =>
              validIds.contains(e.sourceId) &&
              validIds.contains(e.targetId) &&
              e.sourceId != e.targetId,
        )
        .toList();
    return GraphSnapshot(nodes: nodes, edges: edges);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsteriaTheme.backgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Top section with animated logo and main text
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Asteria animated logo
                      AsteriaLoadingAnimation(
                        size: 96,
                        color: AsteriaTheme.textPrimary,
                      ),
                      const SizedBox(height: AsteriaTheme.spacingLarge),
                      // Dynamic status text
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AsteriaTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Minimal bottom spacer to keep vertical balance
              const SizedBox(height: AsteriaTheme.spacingXXLarge),

              // No in-page graph preview; navigate to a dedicated page when ready

              // Bottom overlay for completion message and continue button
              if (_showContinue)
                Container(
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  child: Container(
                    decoration: AsteriaTheme.cleanCardDecoration(),
                    padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Screenshot this and click Continue',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AsteriaTheme.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AsteriaTheme.spacingLarge),
                        SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _navigateToStarMap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AsteriaTheme.secondaryColor,
                              foregroundColor: AsteriaTheme.accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AsteriaTheme.radiusXLarge,
                                ),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
