import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/youtube_service.dart';
import '../theme.dart';
import 'timer_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  String _statusMessage = 'Initializing...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    // Setup continuous spinning animation
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Start spinning
    _spinController.repeat();

    // Start the data processing
    _startProcessing();
  }

  @override
  void dispose() {
    _spinController.dispose();
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

      // Step 5: Complete
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

      // Start slowing down the spin
      _slowDownAndStop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _progress = 1.0;
      });

      // Still slow down even on error
      _slowDownAndStop();
    }
  }

  void _slowDownAndStop() async {
    // Stop the infinite loop
    _spinController.stop();

    // Create a deceleration animation
    _spinController.duration = const Duration(milliseconds: 2000);

    // Animate from current position to next full rotation (1.0)
    await _spinController.animateTo(1.0, curve: Curves.easeOutCubic);

    // Wait a moment before transitioning
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Navigate to timer page
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TimerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Paper flip transition
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Same paper background as sign-in
          Container(decoration: AsteriaTheme.gradientOverlayDecoration()),

          // Decorative paper layers
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 200,
                height: 200,
                decoration: AsteriaTheme.paperCardDecoration(
                  backgroundColor: AsteriaTheme.primaryLight,
                  elevation: AsteriaTheme.elevationLow,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Opacity(
              opacity: 0.25,
              child: Container(
                width: 250,
                height: 250,
                decoration: AsteriaTheme.paperCardDecoration(
                  backgroundColor: AsteriaTheme.secondaryLight,
                  elevation: AsteriaTheme.elevationLow,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Spinning logo
                  AnimatedBuilder(
                    animation: _spinController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _spinController.value * 2 * math.pi,
                        child: Container(
                          decoration: AsteriaTheme.elevatedPaperDecoration(
                            backgroundColor: AsteriaTheme.backgroundPrimary,
                          ),
                          padding: const EdgeInsets.all(
                            AsteriaTheme.spacingXLarge,
                          ),
                          child: SvgPicture.asset(
                            'assets/Logos/Asteri.svg',
                            width: 160,
                            height: 160,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AsteriaTheme.spacingXLarge),

                  // Status message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AsteriaTheme.spacingLarge,
                      vertical: AsteriaTheme.spacingMedium,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AsteriaTheme.spacingLarge,
                    ),
                    decoration: AsteriaTheme.paperCardDecoration(),
                    child: Column(
                      children: [
                        Text(
                          _statusMessage,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AsteriaTheme.primaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AsteriaTheme.spacingMedium),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AsteriaTheme.radiusSmall,
                          ),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 8,
                            backgroundColor: AsteriaTheme.backgroundTertiary,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AsteriaTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Subtle hint text
                  Padding(
                    padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                    child: Text(
                      'Building your connection network...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AsteriaTheme.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
