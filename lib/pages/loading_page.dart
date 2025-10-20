import 'dart:async';
import 'package:flutter/material.dart';
// removed svg loader in favor of hourglass
import '../services/youtube_service.dart';
import '../services/openai_service.dart';
import '../models/passion_graph.dart';
import '../widgets/passion_graph.dart';
import '../widgets/hourglass_loader.dart';
import 'dart:math' as math;
import '../theme.dart';
import 'community_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  String _statusMessage = 'Initializing...';
  double _progress = 0.0;
  bool _showContinue = false;
  GraphSnapshot? _graph;

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
        _progress = 0.1;
      });

      await YouTubeService.syncSubscriptionsToSupabase(
        full: true,
        maxResults: 50,
      );

      if (!mounted) return;

      // Step 2: Sync liked videos
      setState(() {
        _statusMessage = 'Analyzing your social graph...';
        _progress = 0.3;
      });

      await YouTubeService.syncLikedVideosToSupabase(
        full: true,
        maxResults: 50,
      );

      if (!mounted) return;

      // Step 3: Create embeddings
      setState(() {
        _statusMessage = 'Discovering your connection patterns...';
        _progress = 0.5;
      });

      await YouTubeService.embedUserYouTubeProfile(full: true);

      if (!mounted) return;

      // Step 4: Assign cluster
      setState(() {
        _statusMessage = 'Finding your tribe...';
        _progress = 0.7;
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
        _progress = 0.85;
      });

      final subs = await YouTubeService.fetchAllSubscriptions(pageSize: 50);
      final likes = await YouTubeService.fetchAllLikedVideos(
        pageSize: 50,
        maxItems: 100,
      );
      final snapshot = await OpenAIService.summarizePassions(
        subscriptions: subs,
        likedVideos: likes,
      );

      // Seed initial circular layout
      final int n = snapshot.nodes.length;
      for (int i = 0; i < n; i++) {
        final double angle = (i / n) * 6.28318530718; // 2*pi
        snapshot.nodes[i].x = 140 * math.cos(angle);
        snapshot.nodes[i].y = 140 * math.sin(angle);
      }

      setState(() {
        _graph = snapshot;
        _statusMessage = 'Almost ready...';
        _progress = 0.95;
      });

      // Step 6: Complete
      setState(() {
        _statusMessage = 'Almost ready...';
        _progress = 0.9;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _statusMessage = 'All set!';
        _progress = 1.0;
      });

      // Show instruction then Continue after delay
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      setState(() {
        _showContinue = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _progress = 1.0;
        _showContinue = true;
      });
    }
  }

  void _navigateToCommunity() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommunityPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AsteriaTheme.animationMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_graph == null) ...[
                    const Spacer(flex: 3),
                    // Hourglass loader
                    const HourglassLoader(size: 120),
                    const SizedBox(height: AsteriaTheme.spacingLarge),
                    // Main heading
                    Text(
                      'Find your constellation.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AsteriaTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AsteriaTheme.spacingMedium),
                    // Subheading
                    Text(
                      'CONNECT WITH PEOPLE WHO SEE THE WORLD LIKE YOU',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AsteriaTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AsteriaTheme.spacingXXLarge),
                  ] else ...[
                    const Spacer(flex: 2),
                  ],

                  // Graph canvas (when available)
                  if (_graph != null) ...[
                    Container(
                      height: 360,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AsteriaTheme.spacingLarge,
                      ),
                      decoration: AsteriaTheme.cleanCardDecoration(),
                      child: PassionGraph(snapshot: _graph!),
                    ),
                    const Spacer(flex: 2),
                  ],

                  // Status message and progress (only while no graph yet)
                  if (!_showContinue && _graph == null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AsteriaTheme.spacingLarge,
                        vertical: AsteriaTheme.spacingMedium,
                      ),
                      decoration: AsteriaTheme.cleanCardDecoration(),
                      child: Column(
                        children: [
                          Text(
                            _statusMessage,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AsteriaTheme.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AsteriaTheme.spacingMedium),
                          Container(
                            height: 4,
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: AsteriaTheme.backgroundTertiary,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AsteriaTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(flex: 3),
                  const SizedBox(height: 72), // space for bottom overlay
                ],
              ),

              // Bottom overlay for completion message and continue button
              if (_showContinue)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
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
                              onPressed: _navigateToCommunity,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
