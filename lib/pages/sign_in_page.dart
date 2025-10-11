import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Setup entrance animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Logo floats in from top
    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    // Button appears after logo
    _buttonAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
      // Navigation will be handled by AuthGate
    } catch (e) {
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
    return Scaffold(
      body: Stack(
        children: [
          // Paper background with soft shadows
          Container(decoration: AsteriaTheme.gradientOverlayDecoration()),

          // Decorative paper layers in corners for depth
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AsteriaTheme.spacingXXLarge),

                      // Animated logo
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -50 * (1 - _logoAnimation.value)),
                            child: Opacity(
                              opacity: _logoAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          decoration: AsteriaTheme.elevatedPaperDecoration(
                            backgroundColor: AsteriaTheme.backgroundPrimary,
                          ),
                          padding: const EdgeInsets.all(
                            AsteriaTheme.spacingXLarge,
                          ),
                          child: SvgPicture.asset(
                            'assets/Logos/Asteri.svg',
                            width: 180,
                            height: 180,
                          ),
                        ),
                      ),

                      const SizedBox(height: AsteriaTheme.spacingXLarge),

                      // Welcome text
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoAnimation.value,
                            child: child,
                          );
                        },
                        child: Text(
                          'Welcome to Asteria',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AsteriaTheme.primaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AsteriaTheme.spacingSmall),

                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoAnimation.value * 0.8,
                            child: child,
                          );
                        },
                        child: Text(
                          'Connect with like-minded people',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AsteriaTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AsteriaTheme.spacingXXLarge),

                      // Sign in button with animation
                      AnimatedBuilder(
                        animation: _buttonAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.5 + (0.5 * _buttonAnimation.value),
                            child: Opacity(
                              opacity: _buttonAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          decoration: AsteriaTheme.paperCardDecoration(
                            elevation: AsteriaTheme.elevationMedium,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _signIn,
                            icon: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AsteriaTheme.textOnPrimary,
                                      ),
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/Logos/google_logo.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AsteriaTheme.spacingMedium,
                                vertical: AsteriaTheme.spacingSmall,
                              ),
                              child: Text(
                                _busy ? 'Signing in...' : 'Sign in with Google',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AsteriaTheme.primaryColor,
                              foregroundColor: AsteriaTheme.textOnPrimary,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),

                      // Error message
                      if (_error != null) ...[
                        const SizedBox(height: AsteriaTheme.spacingLarge),
                        Container(
                          padding: const EdgeInsets.all(
                            AsteriaTheme.spacingMedium,
                          ),
                          decoration: AsteriaTheme.paperCardDecoration(
                            backgroundColor: AsteriaTheme.errorColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AsteriaTheme.errorColor,
                              ),
                              const SizedBox(width: AsteriaTheme.spacingSmall),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AsteriaTheme.errorColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AsteriaTheme.spacingXXLarge),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
