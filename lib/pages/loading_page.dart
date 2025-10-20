import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/youtube_service.dart';
import '../theme.dart';
// import 'timer_page.dart';
import 'community_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _breathController;
  late AnimationController _morphController;
  late AnimationController _fadeController;

  String _statusMessage = 'Initializing...';
  double _progress = 0.0;

  // Animation values
  late Animation<double> _spinAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breathAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup multiple animation controllers
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _breathController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _morphController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Setup animations
    _spinAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.linear));

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _morphAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Start animations
    _spinController.repeat();
    _pulseController.repeat(reverse: true);
    _breathController.repeat(reverse: true);
    _morphController.repeat();
    _fadeController.forward();

    // Start the data processing
    _startProcessing();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _breathController.dispose();
    _morphController.dispose();
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

    // Navigate to communities page (keep TimerPage in project)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommunityPage(),
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
          // Enhanced gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AsteriaTheme.backgroundPrimary,
                  AsteriaTheme.backgroundSecondary,
                  AsteriaTheme.backgroundTertiary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Animated floating paper layers
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Top right floating element
                  Positioned(
                    top: -80 * _breathAnimation.value,
                    right: -60 * _breathAnimation.value,
                    child: Transform.scale(
                      scale: _breathAnimation.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AsteriaTheme.primaryLight.withValues(alpha: 0.3),
                              AsteriaTheme.primaryColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(90),
                          boxShadow: [
                            BoxShadow(
                              color: AsteriaTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom left floating element
                  Positioned(
                    bottom: -100 * _breathAnimation.value,
                    left: -70 * _breathAnimation.value,
                    child: Transform.scale(
                      scale: _breathAnimation.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AsteriaTheme.secondaryLight.withValues(
                                alpha: 0.25,
                              ),
                              AsteriaTheme.secondaryColor.withValues(
                                alpha: 0.1,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(110),
                          boxShadow: [
                            BoxShadow(
                              color: AsteriaTheme.secondaryColor.withValues(
                                alpha: 0.15,
                              ),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main content with enhanced animations
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Multi-layered animated logo
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _spinAnimation,
                        _pulseAnimation,
                        _breathAnimation,
                        _morphAnimation,
                      ]),
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulsing ring
                            Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AsteriaTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      AsteriaTheme.primaryColor.withValues(
                                        alpha: 0.05,
                                      ),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // Middle breathing ring
                            Transform.scale(
                              scale: _breathAnimation.value,
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AsteriaTheme.accentColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            // Main spinning logo container
                            Transform.rotate(
                              angle: _spinAnimation.value * 2 * math.pi,
                              child: Transform.scale(
                                scale: _breathAnimation.value,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration:
                                      AsteriaTheme.elevatedPaperDecoration(
                                        backgroundColor:
                                            AsteriaTheme.backgroundPrimary,
                                      ),
                                  padding: const EdgeInsets.all(
                                    AsteriaTheme.spacingXLarge,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/Logos/Asteri.svg',
                                    width: 140,
                                    height: 140,
                                  ),
                                ),
                              ),
                            ),

                            // Inner morphing accent
                            Transform.scale(
                              scale: 0.3 + (0.1 * _morphAnimation.value),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AsteriaTheme.accentColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      AsteriaTheme.primaryColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AsteriaTheme.accentColor
                                          .withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AsteriaTheme.spacingXXLarge),

                    // Enhanced status message with animation
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(
                            AsteriaTheme.spacingXLarge,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: AsteriaTheme.spacingLarge,
                          ),
                          decoration: AsteriaTheme.elevatedPaperDecoration(
                            backgroundColor: AsteriaTheme.backgroundSecondary,
                          ),
                          child: Column(
                            children: [
                              // Status icon with pulse
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            AsteriaTheme.primaryColor,
                                            AsteriaTheme.primaryLight,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AsteriaTheme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: AsteriaTheme.spacingLarge),

                              // Status text with better typography
                              Text(
                                _statusMessage,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AsteriaTheme.primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: AsteriaTheme.spacingLarge),

                              // Enhanced progress bar
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AsteriaTheme.radiusMedium,
                                  ),
                                  color: AsteriaTheme.backgroundTertiary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AsteriaTheme.shadowLight,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AsteriaTheme.radiusMedium,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AsteriaTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: AsteriaTheme.spacingMedium,
                              ),

                              // Progress percentage
                              Text(
                                '${(_progress * 100).round()}%',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AsteriaTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Enhanced hint text with animation
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Padding(
                          padding: const EdgeInsets.all(
                            AsteriaTheme.spacingXLarge,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Building your connection network...',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AsteriaTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: AsteriaTheme.spacingSmall),

                              // Animated dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  return AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      final delay = index * 0.2;
                                      final animationValue =
                                          (_pulseAnimation.value + delay) % 1.0;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal:
                                              AsteriaTheme.spacingXSmall,
                                        ),
                                        child: Transform.scale(
                                          scale: 0.5 + (0.5 * animationValue),
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AsteriaTheme.accentColor
                                                  .withValues(
                                                    alpha:
                                                        0.3 +
                                                        (0.7 * animationValue),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
