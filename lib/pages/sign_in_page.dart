import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  late AnimationController _animationController;
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Setup entrance animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Subtle breathing animation for logo
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Very subtle rotation animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Logo floats in and draws itself
    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );

    // Button appears after logo
    _buttonAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    );

    // Breathing effect (subtle scale)
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Subtle rotation
    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _breathingController.repeat(reverse: true);
    _rotationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _breathingController.dispose();
    _rotationController.dispose();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                    animation: Listenable.merge([
                      _logoAnimation,
                      _breathingAnimation,
                      _rotationAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -30 * (1 - _logoAnimation.value)),
                        child: Transform.scale(
                          scale:
                              _logoAnimation.value * _breathingAnimation.value,
                          child: Transform.rotate(
                            angle:
                                _rotationAnimation.value * _logoAnimation.value,
                            child: Opacity(
                              opacity: _logoAnimation.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle glow effect behind logo
                                  Container(
                                    width: 280 * _logoAnimation.value,
                                    height: 280 * _logoAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AsteriaTheme.primaryColor.withValues(
                                            alpha: 0.05 * _logoAnimation.value,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Main logo with drawing effect
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [
                                          0.0,
                                          _logoAnimation.value,
                                          _logoAnimation.value,
                                          1.0,
                                        ],
                                        colors: const [
                                          Colors.white, // mask color (kept white for reveal)
                                          Colors.white,
                                          Colors.transparent,
                                          Colors.transparent,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: SvgPicture.asset(
                                      'assets/Logos/Asteri.svg',
                                      width: 260,
                                      height: 260,
                                      colorFilter: const ColorFilter.mode(
                                        AsteriaTheme.primaryColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AsteriaTheme.spacingXXLarge),

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
                          ?.copyWith(
                            color: AsteriaTheme.primaryColor,
                            fontWeight: FontWeight.w400,
                          ),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AsteriaTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: AsteriaTheme.spacingXXLarge),

                  // Sign in button with animation - Black pill-shaped button
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
                    child: SizedBox(
                      width: 300,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF2C3E50,
                          ), // Dark blue-grey/black
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AsteriaTheme.spacingLarge,
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/Logos/google_logo.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(
                                    width: AsteriaTheme.spacingMedium,
                                  ),
                                  Text(
                                    'Sign in with Google',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: AsteriaTheme.spacingLarge),
                    Container(
                      padding: const EdgeInsets.all(AsteriaTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: AsteriaTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AsteriaTheme.radiusMedium,
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
                                  ?.copyWith(color: AsteriaTheme.errorColor),
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
    );
  }
}
