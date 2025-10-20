import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/youtube_service.dart';
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
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  String _statusMessage = 'Initializing...';
  double _progress = 0.0;
  bool _showSignInButton = false;

  // Animation values
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controllers
    _fadeController = AnimationController(
      duration: AsteriaTheme.animationMedium,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: AsteriaTheme.animationSlow,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: AsteriaTheme.curveElegant,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: AsteriaTheme.curveSmooth,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: AsteriaTheme.curveSubtle,
      ),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);

    // Start the data processing
    _startProcessing();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
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

      // Show sign-in button after completion
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      setState(() {
        _showSignInButton = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _progress = 1.0;
        _showSignInButton = true;
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
      backgroundColor: AsteriaTheme.backgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Main logo with subtle animation
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: AsteriaTheme.cleanCardDecoration(),
                              padding: const EdgeInsets.all(
                                AsteriaTheme.spacingLarge,
                              ),
                              child: SvgPicture.asset(
                                'assets/Logos/Asteri.svg',
                                colorFilter: const ColorFilter.mode(
                                  AsteriaTheme.primaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: AsteriaTheme.spacingXXLarge),

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

                // Status message and progress
                if (!_showSignInButton) ...[
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

                // Google Sign-In Button
                if (_showSignInButton) ...[
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 280,
                          height: 50,
                          decoration: AsteriaTheme.pillDecoration(
                            backgroundColor: AsteriaTheme.secondaryColor,
                          ),
                          child: ElevatedButton(
                            onPressed: _navigateToCommunity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AsteriaTheme.radiusXLarge,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Logo
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'https://developers.google.com/identity/images/g-logo.png',
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: AsteriaTheme.spacingMedium,
                                ),
                                Text(
                                  'Sign in with Google',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AsteriaTheme.accentColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
