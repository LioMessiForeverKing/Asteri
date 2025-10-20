import 'dart:math' as math;
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
      backgroundColor: const Color(0xFFF5F1EB), // Light brownish beige
      body: Stack(
        children: [
          // Hand-drawn decorative elements
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _HandDrawnBackgroundPainter(
                  animationValue: _logoAnimation.value,
                ),
                child: Container(),
              );
            },
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

                      // Animated logo with hand-drawn effect
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
                                  _logoAnimation.value *
                                  _breathingAnimation.value,
                              child: Transform.rotate(
                                angle:
                                    _rotationAnimation.value *
                                    _logoAnimation.value,
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
                                              AsteriaTheme.primaryColor
                                                  .withValues(
                                                    alpha:
                                                        0.05 *
                                                        _logoAnimation.value,
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
                                              Colors.white,
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
                                      // Subtle sketch lines overlay
                                      if (_logoAnimation.value > 0.3)
                                        Opacity(
                                          opacity:
                                              (_logoAnimation.value - 0.3) *
                                              0.15,
                                          child: CustomPaint(
                                            size: const Size(260, 260),
                                            painter: _SketchLinesPainter(),
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AsteriaTheme.textSecondary),
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
                          padding: const EdgeInsets.all(
                            AsteriaTheme.spacingMedium,
                          ),
                          decoration: BoxDecoration(
                            color: AsteriaTheme.errorColor.withValues(
                              alpha: 0.1,
                            ),
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

// Custom painter for hand-drawn sketch lines effect
class _SketchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AsteriaTheme.primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // Fixed seed for consistent pattern

    // Draw subtle sketch lines around the logo to give hand-drawn feel
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2) / 12;
      final radius = size.width * 0.35;

      // Add slight randomness to make it feel hand-drawn
      final offsetX = random.nextDouble() * 4 - 2;
      final offsetY = random.nextDouble() * 4 - 2;

      final startX = size.width / 2 + math.cos(angle) * radius + offsetX;
      final startY = size.height / 2 + math.sin(angle) * radius + offsetY;

      final endX = size.width / 2 + math.cos(angle) * (radius + 8) + offsetX;
      final endY = size.height / 2 + math.sin(angle) * (radius + 8) + offsetY;

      // Draw short sketch marks
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw some subtle concentric circles for depth
    for (int i = 1; i <= 2; i++) {
      final circleRadius = size.width * 0.35 * (1 + i * 0.15);
      final circlePaint = Paint()
        ..color = AsteriaTheme.primaryColor.withValues(alpha: 0.08 / i)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        circleRadius,
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for hand-drawn background decorations
class _HandDrawnBackgroundPainter extends CustomPainter {
  final double animationValue;

  _HandDrawnBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);

    // Draw immediately - don't wait for animation
    final opacity = animationValue.clamp(0.0, 1.0);

    // Draw notebook paper lines
    _drawNotebookLines(canvas, size, opacity);

    // Draw paper holes (like a spiral notebook)
    _drawPaperHoles(canvas, size, opacity);

    // Draw margin line (red line on left)
    _drawMarginLine(canvas, size, opacity);

    // Draw paper texture/wrinkles
    _drawPaperTexture(canvas, size, opacity, random);

    // Top left corner doodles
    _drawCornerDoodle(
      canvas,
      AsteriaTheme.primaryColor.withValues(alpha: 0.15 * opacity),
      Offset(size.width * 0.1, size.height * 0.15),
      30,
    );

    // Top right corner stars and sparkles
    _drawSparkles(
      canvas,
      AsteriaTheme.primaryColor.withValues(alpha: 0.2 * opacity),
      Offset(size.width * 0.85, size.height * 0.12),
      random,
    );

    // Bottom left wavy lines
    _drawWavyLines(
      canvas,
      AsteriaTheme.primaryColor.withValues(alpha: 0.12 * opacity),
      Offset(size.width * 0.08, size.height * 0.85),
    );

    // Bottom right small constellation
    _drawConstellation(
      canvas,
      AsteriaTheme.primaryColor.withValues(alpha: 0.18 * opacity),
      Offset(size.width * 0.88, size.height * 0.88),
      random,
    );

    // Scattered dots and marks
    _drawScatteredMarks(
      canvas,
      AsteriaTheme.primaryColor.withValues(alpha: 0.1 * opacity),
      size,
      random,
    );

    // Draw corner creases
    _drawCornerCreases(canvas, size, opacity);
  }

  void _drawNotebookLines(Canvas canvas, Size size, double opacity) {
    final linePaint = Paint()
      ..color = const Color(0xFF8BB7DD).withValues(alpha: 0.15 * opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines across the page
    final lineSpacing = 32.0;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      // Add slight waviness to lines to make them feel hand-drawn
      final path = Path();
      path.moveTo(60, y);

      for (double x = 60; x < size.width - 20; x += 20) {
        final offset = math.sin(x / 50) * 0.5;
        path.lineTo(x, y + offset);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  void _drawPaperHoles(Canvas canvas, Size size, double opacity) {
    final holePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.08 * opacity)
      ..style = PaintingStyle.fill;

    final holeOutlinePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.12 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw 3 holes on the left side
    final holeCount = 3;
    final holeSpacing = size.height / (holeCount + 1);

    for (int i = 1; i <= holeCount; i++) {
      final y = holeSpacing * i;
      final holeRadius = 6.0;

      // Shadow
      canvas.drawCircle(Offset(25, y + 1), holeRadius, holePaint);

      // Hole
      canvas.drawCircle(
        Offset(25, y),
        holeRadius,
        Paint()..color = const Color(0xFFE8E4DE).withValues(alpha: opacity),
      );

      // Outline
      canvas.drawCircle(Offset(25, y), holeRadius, holeOutlinePaint);
    }
  }

  void _drawMarginLine(Canvas canvas, Size size, double opacity) {
    final marginPaint = Paint()
      ..color = const Color(0xFFE57A6F).withValues(alpha: 0.2 * opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw vertical margin line on the left
    canvas.drawLine(Offset(55, 10), Offset(55, size.height - 10), marginPaint);
  }

  void _drawPaperTexture(
    Canvas canvas,
    Size size,
    double opacity,
    math.Random random,
  ) {
    final texturePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.02 * opacity)
      ..style = PaintingStyle.fill;

    // Draw subtle texture spots
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      canvas.drawCircle(Offset(x, y), radius, texturePaint);
    }

    // Draw some subtle wrinkle lines
    final wrinklePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.03 * opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;

      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        startX + (random.nextDouble() - 0.5) * 100,
        startY + (random.nextDouble() - 0.5) * 100,
        startX + (random.nextDouble() - 0.5) * 150,
        startY + (random.nextDouble() - 0.5) * 150,
      );

      canvas.drawPath(path, wrinklePaint);
    }
  }

  void _drawCornerCreases(Canvas canvas, Size size, double opacity) {
    final creasePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.05 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Top right corner crease
    final topRightPath = Path();
    topRightPath.moveTo(size.width - 30, 0);
    topRightPath.lineTo(size.width, 30);
    canvas.drawPath(topRightPath, creasePaint);

    // Bottom left corner crease
    final bottomLeftPath = Path();
    bottomLeftPath.moveTo(0, size.height - 30);
    bottomLeftPath.lineTo(30, size.height);
    canvas.drawPath(bottomLeftPath, creasePaint);
  }

  void _drawCornerDoodle(
    Canvas canvas,
    Color color,
    Offset center,
    double size,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw curved line
    final path = Path();
    path.moveTo(center.dx - size / 2, center.dy);
    path.quadraticBezierTo(
      center.dx,
      center.dy - size / 3,
      center.dx + size / 2,
      center.dy,
    );
    canvas.drawPath(path, paint);

    // Draw small circles
    for (int i = 0; i < 3; i++) {
      final angle = (i * math.pi * 2) / 3;
      final x = center.dx + math.cos(angle) * size * 0.6;
      final y = center.dy + math.sin(angle) * size * 0.6;
      canvas.drawCircle(Offset(x, y), 2, paint..style = PaintingStyle.fill);
    }
  }

  void _drawSparkles(
    Canvas canvas,
    Color color,
    Offset center,
    math.Random random,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw multiple small sparkles
    for (int i = 0; i < 5; i++) {
      final offsetX = (random.nextDouble() - 0.5) * 60;
      final offsetY = (random.nextDouble() - 0.5) * 60;
      final sparkleCenter = Offset(center.dx + offsetX, center.dy + offsetY);

      // Draw cross for sparkle
      canvas.drawLine(
        Offset(sparkleCenter.dx - 4, sparkleCenter.dy),
        Offset(sparkleCenter.dx + 4, sparkleCenter.dy),
        paint,
      );
      canvas.drawLine(
        Offset(sparkleCenter.dx, sparkleCenter.dy - 4),
        Offset(sparkleCenter.dx, sparkleCenter.dy + 4),
        paint,
      );
    }
  }

  void _drawWavyLines(Canvas canvas, Color color, Offset start) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw 3 wavy horizontal lines
    for (int line = 0; line < 3; line++) {
      final path = Path();
      final y = start.dy + (line * 8);
      path.moveTo(start.dx, y);

      for (double x = 0; x < 50; x += 10) {
        path.quadraticBezierTo(
          start.dx + x + 5,
          y + (line % 2 == 0 ? -3 : 3),
          start.dx + x + 10,
          y,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawConstellation(
    Canvas canvas,
    Color color,
    Offset center,
    math.Random random,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create 5 star points
    final points = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final offsetX = (random.nextDouble() - 0.5) * 40;
      final offsetY = (random.nextDouble() - 0.5) * 40;
      points.add(Offset(center.dx + offsetX, center.dy + offsetY));
    }

    // Draw lines connecting points
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw dots at points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 1.5, dotPaint);
    }
  }

  void _drawScatteredMarks(
    Canvas canvas,
    Color color,
    Size size,
    math.Random random,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw random small marks across the page
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // Avoid the center area where logo is
      if ((x > size.width * 0.3 && x < size.width * 0.7) &&
          (y > size.height * 0.25 && y < size.height * 0.65)) {
        continue;
      }

      final markType = random.nextDouble();

      if (markType < 0.33) {
        // Small dash
        canvas.drawLine(Offset(x, y), Offset(x + 8, y), paint);
      } else if (markType < 0.66) {
        // Small dot
        canvas.drawCircle(Offset(x, y), 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        // Small cross
        canvas.drawLine(Offset(x - 3, y - 3), Offset(x + 3, y + 3), paint);
        canvas.drawLine(Offset(x + 3, y - 3), Offset(x - 3, y + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandDrawnBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
