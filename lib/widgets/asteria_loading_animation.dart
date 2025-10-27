import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';

class AsteriaLoadingAnimation extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;

  const AsteriaLoadingAnimation({
    super.key,
    this.size = 64.0,
    this.message,
    this.color,
  });

  @override
  State<AsteriaLoadingAnimation> createState() =>
      _AsteriaLoadingAnimationState();
}

class _AsteriaLoadingAnimationState extends State<AsteriaLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation: 0° → 180° → 360° over 2 seconds
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Scale animation: 20% → 120% → 20% over 2 seconds (dramatic effect)
    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create the rotation animation with keyframes
    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 2 * math.pi, // 360 degrees in radians
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );

    // Create the scale animation with dramatic keyframes
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.2, // Start very small (20%)
          end: 1.2, // Grow to 120%
        ).chain(CurveTween(curve: Curves.easeOutBack)), // Bouncy expansion
        weight: 50, // First half: dramatic growth
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2, // From 120%
          end: 0.2, // Shrink back to 20%
        ).chain(CurveTween(curve: Curves.easeInBack)), // Bouncy contraction
        weight: 50, // Second half: dramatic shrink
      ),
    ]).animate(_scaleController);

    // Start all animations with infinite repeat
    _rotationController.repeat();
    _scaleController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AsteriaTheme.textPrimary;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: SvgPicture.asset(
              'assets/Logos/Asteri.svg',
              width: widget.size,
              height: widget.size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        );
      },
    );
  }
}

/// A full-screen loading widget that centers the Asteria animation
class AsteriaLoadingScreen extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? logoColor;

  const AsteriaLoadingScreen({
    super.key,
    this.message,
    this.backgroundColor,
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AsteriaTheme.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: AsteriaLoadingAnimation(
            size: 80.0, // Slightly larger for full screen
            message: message,
            color: logoColor,
          ),
        ),
      ),
    );
  }
}
