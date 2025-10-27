import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class StarMapPage extends StatefulWidget {
  const StarMapPage({super.key});

  @override
  State<StarMapPage> createState() => _StarMapPageState();
}

class _StarMapPageState extends State<StarMapPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Hardcoded stars data
  final List<StarData> _stars = [
    StarData(
      id: 'you',
      name: 'You',
      x: 0.5,
      y: 0.5,
      isCurrentUser: true,
      interests: ['Music', 'Technology', 'Art'],
      similarity: 1.0,
    ),
    StarData(
      id: 'star1',
      name: 'Alex',
      x: 0.3,
      y: 0.4,
      isCurrentUser: false,
      interests: ['Music', 'Gaming', 'Photography'],
      similarity: 0.85,
    ),
    StarData(
      id: 'star2',
      name: 'Sam',
      x: 0.7,
      y: 0.3,
      isCurrentUser: false,
      interests: ['Technology', 'Science', 'Books'],
      similarity: 0.78,
    ),
    StarData(
      id: 'star3',
      name: 'Jordan',
      x: 0.2,
      y: 0.7,
      isCurrentUser: false,
      interests: ['Art', 'Design', 'Music'],
      similarity: 0.92,
    ),
    StarData(
      id: 'star4',
      name: 'Casey',
      x: 0.8,
      y: 0.6,
      isCurrentUser: false,
      interests: ['Sports', 'Fitness', 'Travel'],
      similarity: 0.45,
    ),
    StarData(
      id: 'star5',
      name: 'Riley',
      x: 0.4,
      y: 0.2,
      isCurrentUser: false,
      interests: ['Music', 'Movies', 'Cooking'],
      similarity: 0.67,
    ),
    StarData(
      id: 'star6',
      name: 'Morgan',
      x: 0.6,
      y: 0.8,
      isCurrentUser: false,
      interests: ['Technology', 'Gaming', 'Music'],
      similarity: 0.73,
    ),
    StarData(
      id: 'star7',
      name: 'Taylor',
      x: 0.1,
      y: 0.5,
      isCurrentUser: false,
      interests: ['Art', 'Photography', 'Travel'],
      similarity: 0.58,
    ),
    StarData(
      id: 'star8',
      name: 'Avery',
      x: 0.9,
      y: 0.4,
      isCurrentUser: false,
      interests: ['Science', 'Books', 'Technology'],
      similarity: 0.69,
    ),
    // Additional stars for scrollable map
    StarData(
      id: 'star9',
      name: 'Blake',
      x: 0.15,
      y: 0.2,
      isCurrentUser: false,
      interests: ['Design', 'Art', 'Fashion'],
      similarity: 0.76,
    ),
    StarData(
      id: 'star10',
      name: 'Cameron',
      x: 0.85,
      y: 0.8,
      isCurrentUser: false,
      interests: ['Science', 'Technology', 'Innovation'],
      similarity: 0.82,
    ),
    StarData(
      id: 'star11',
      name: 'Drew',
      x: 0.1,
      y: 0.8,
      isCurrentUser: false,
      interests: ['Music', 'Writing', 'Poetry'],
      similarity: 0.64,
    ),
    StarData(
      id: 'star12',
      name: 'Emery',
      x: 0.9,
      y: 0.2,
      isCurrentUser: false,
      interests: ['Business', 'Finance', 'Leadership'],
      similarity: 0.38,
    ),
    StarData(
      id: 'star13',
      name: 'Finley',
      x: 0.25,
      y: 0.9,
      isCurrentUser: false,
      interests: ['Nature', 'Hiking', 'Photography'],
      similarity: 0.71,
    ),
    StarData(
      id: 'star14',
      name: 'Gray',
      x: 0.75,
      y: 0.1,
      isCurrentUser: false,
      interests: ['Gaming', 'Streaming', 'Entertainment'],
      similarity: 0.55,
    ),
    StarData(
      id: 'star15',
      name: 'Harper',
      x: 0.05,
      y: 0.3,
      isCurrentUser: false,
      interests: ['Education', 'Teaching', 'Learning'],
      similarity: 0.61,
    ),
    StarData(
      id: 'star16',
      name: 'Indigo',
      x: 0.95,
      y: 0.7,
      isCurrentUser: false,
      interests: ['Fashion', 'Beauty', 'Lifestyle'],
      similarity: 0.43,
    ),
  ];

  StarData? _selectedStar;
  bool _showConversationCard = false;

  // Zoom and pan state
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onStarTap(StarData star) {
    if (star.isCurrentUser) return;

    setState(() {
      _selectedStar = star;
      _showConversationCard = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _closeConversationCard() {
    setState(() {
      _showConversationCard = false;
      _selectedStar = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsteriaTheme.backgroundPrimary,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AsteriaTheme.backgroundPrimary,
                  AsteriaTheme.backgroundSecondary,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Star map
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildStarMap(),
                  ),
                ),
              ],
            ),
          ),

          // Conversation card overlay
          if (_showConversationCard && _selectedStar != null)
            _buildConversationCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AsteriaTheme.textPrimary,
            ),
          ),

          // Title
          Expanded(
            child: Column(
              children: [
                Text(
                  'Star Map',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AsteriaTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Pinch to zoom • Drag to pan • Scroll to explore',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AsteriaTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // Reset zoom button
          IconButton(
            onPressed: () {
              setState(() {
                _scale = 1.0;
                _offset = Offset.zero;
              });
            },
            icon: const Icon(
              Icons.center_focus_strong_rounded,
              color: AsteriaTheme.textPrimary,
            ),
            tooltip: 'Reset zoom',
          ),

          // Search button
          IconButton(
            onPressed: () {
              // Search functionality will be implemented later
            },
            icon: const Icon(
              Icons.search_rounded,
              color: AsteriaTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarMap() {
    final screenSize = MediaQuery.of(context).size;

    // Calculate bounds to fit all stars
    final minX = _stars.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = _stars.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final minY = _stars.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = _stars.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Add padding around the bounds
    final padding = 0.1;
    final contentWidth = (maxX - minX + 2 * padding).clamp(0.3, 1.0);
    final contentHeight = (maxY - minY + 2 * padding).clamp(0.3, 1.0);

    // Calculate minimum scale to fit all stars
    final minScaleX = screenSize.width / (contentWidth * screenSize.width);
    final minScaleY = screenSize.height / (contentHeight * screenSize.height);
    final minScale = (minScaleX > minScaleY ? minScaleX : minScaleY).clamp(
      0.8,
      1.0,
    );

    return GestureDetector(
      onTap: _closeConversationCard,
      onScaleStart: (details) {
        _lastPanPosition = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Handle zoom with proper bounds
          final newScale = (_scale * details.scale).clamp(minScale, 3.0);
          _scale = newScale;

          // Handle pan with bounds checking
          if (_lastPanPosition != null) {
            final delta = details.focalPoint - _lastPanPosition!;
            final newOffset = _offset + delta;

            // Calculate pan bounds based on current scale
            final maxOffsetX = (screenSize.width * (1 - 1 / _scale)) / 2;
            final maxOffsetY = (screenSize.height * (1 - 1 / _scale)) / 2;

            _offset = Offset(
              newOffset.dx.clamp(-maxOffsetX, maxOffsetX),
              newOffset.dy.clamp(-maxOffsetY, maxOffsetY),
            );
          }
          _lastPanPosition = details.focalPoint;
        });
      },
      onScaleEnd: (details) {
        _lastPanPosition = null;
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Transform.translate(
            offset: _offset,
            child: Transform.scale(
              scale: _scale,
              child: SizedBox(
                width: screenSize.width * 2, // Make map 2x wider for scrolling
                height:
                    screenSize.height * 2, // Make map 2x taller for scrolling
                child: Stack(
                  children: [
                    // Grid background
                    _buildGridBackground(),
                    // Stars
                    ..._stars.map((star) => _buildStar(star)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: GridBackgroundPainter()),
    );
  }

  Widget _buildStar(StarData star) {
    final screenSize = MediaQuery.of(context).size;
    // Position stars relative to the larger scrollable area
    final mapWidth = screenSize.width * 2;
    final mapHeight = screenSize.height * 2;
    final x = star.x * mapWidth;
    final y = star.y * mapHeight;

    return Positioned(
      left: x - 20, // Center the star
      top: y - 20,
      child: GestureDetector(
        onTap: () => _onStarTap(star),
        child: AnimatedBuilder(
          animation: star.isCurrentUser ? _pulseAnimation : _fadeAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: star.isCurrentUser
                  ? 1.0 + (_pulseAnimation.value * 0.2)
                  : 1.0,
              child: SizedBox(
                width: star.isCurrentUser ? 60 : 40,
                height: star.isCurrentUser ? 60 : 40,
                child: CustomPaint(
                  painter: star.isCurrentUser
                      ? EnhancedUserStarPainter(
                          color: AsteriaTheme.primaryColor,
                          glowIntensity: _pulseAnimation.value * 0.8 + 0.2,
                          animationValue: _pulseAnimation.value,
                        )
                      : StarPainter(
                          color: _getStarColor(star.similarity),
                          isGlowing: false,
                          glowIntensity: 0.3,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStarColor(double similarity) {
    if (similarity > 0.8) {
      return AsteriaTheme.primaryColor;
    } else if (similarity > 0.6) {
      return AsteriaTheme.primaryLight;
    } else if (similarity > 0.4) {
      return AsteriaTheme.secondaryColor;
    } else {
      return AsteriaTheme.textTertiary;
    }
  }

  Widget _buildConversationCard() {
    if (_selectedStar == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AsteriaTheme.spacingLarge),
          decoration: AsteriaTheme.elevatedCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                decoration: BoxDecoration(
                  color: AsteriaTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AsteriaTheme.radiusLarge),
                    topRight: Radius.circular(AsteriaTheme.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    // Star icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AsteriaTheme.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AsteriaTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AsteriaTheme.spacingMedium),

                    // Name and similarity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStar!.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AsteriaTheme.textOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${(_selectedStar!.similarity * 100).toInt()}% match',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AsteriaTheme.textOnPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      onPressed: _closeConversationCard,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AsteriaTheme.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shared interests
                    Text(
                      'What you both like',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AsteriaTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AsteriaTheme.spacingSmall),
                    Wrap(
                      spacing: AsteriaTheme.spacingSmall,
                      runSpacing: AsteriaTheme.spacingSmall,
                      children: _selectedStar!.interests
                          .where(
                            (interest) => [
                              'Music',
                              'Technology',
                              'Art',
                            ].contains(interest),
                          )
                          .map(
                            (interest) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AsteriaTheme.spacingMedium,
                                vertical: AsteriaTheme.spacingSmall,
                              ),
                              decoration: BoxDecoration(
                                color: AsteriaTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AsteriaTheme.radiusSmall,
                                ),
                              ),
                              child: Text(
                                interest,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AsteriaTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: AsteriaTheme.spacingLarge),

                    // Conversation starters
                    Text(
                      'Conversation starters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AsteriaTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AsteriaTheme.spacingSmall),
                    ..._buildConversationStarters().map(
                      (starter) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AsteriaTheme.spacingSmall,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(
                                top: 6,
                                right: AsteriaTheme.spacingSmall,
                              ),
                              decoration: BoxDecoration(
                                color: AsteriaTheme.primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                starter,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AsteriaTheme.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AsteriaTheme.spacingLarge),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Start conversation functionality will be implemented later
                              _closeConversationCard();
                            },
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text('Start Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AsteriaTheme.primaryColor,
                              foregroundColor: AsteriaTheme.textOnPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AsteriaTheme.spacingMedium),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Save connection functionality will be implemented later
                              _closeConversationCard();
                            },
                            icon: const Icon(Icons.bookmark_rounded),
                            label: const Text('Save'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AsteriaTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildConversationStarters() {
    if (_selectedStar == null) return [];

    final sharedInterests = _selectedStar!.interests
        .where((interest) => ['Music', 'Technology', 'Art'].contains(interest))
        .toList();

    if (sharedInterests.contains('Music')) {
      return [
        'What\'s your favorite music genre?',
        'Any recent concerts you\'ve been to?',
        'Do you play any instruments?',
      ];
    } else if (sharedInterests.contains('Technology')) {
      return [
        'What programming languages do you use?',
        'Any interesting tech projects you\'re working on?',
        'What\'s your take on AI developments?',
      ];
    } else if (sharedInterests.contains('Art')) {
      return [
        'What\'s your favorite art style?',
        'Do you create any art yourself?',
        'Any art exhibitions you\'ve visited recently?',
      ];
    }

    return [
      'What are you working on these days?',
      'Any interesting hobbies you\'ve picked up?',
      'What\'s something you\'re excited about?',
    ];
  }
}

class StarData {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isCurrentUser;
  final List<String> interests;
  final double similarity;

  StarData({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isCurrentUser,
    required this.interests,
    required this.similarity,
  });
}

class StarPainter extends CustomPainter {
  final Color color;
  final bool isGlowing;
  final double glowIntensity;

  StarPainter({
    required this.color,
    this.isGlowing = false,
    this.glowIntensity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Glow effect
    if (isGlowing) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: glowIntensity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      _drawStar(canvas, center, radius * 1.5, glowPaint);
    }

    // Main star
    final starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _drawStar(canvas, center, radius, starPaint);

    // Star outline
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawStar(canvas, center, radius, outlinePaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final angle = math.pi / 5; // 36 degrees for 5-pointed star

    for (int i = 0; i < 5; i++) {
      final x = center.dx + radius * math.cos(i * 2 * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * 2 * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Inner point
      final innerX =
          center.dx +
          (radius * 0.4) * math.cos((i * 2 + 1) * angle - math.pi / 2);
      final innerY =
          center.dy +
          (radius * 0.4) * math.sin((i * 2 + 1) * angle - math.pi / 2);
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is StarPainter &&
        (oldDelegate.color != color ||
            oldDelegate.isGlowing != isGlowing ||
            oldDelegate.glowIntensity != glowIntensity);
  }
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AsteriaTheme.textTertiary.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnhancedUserStarPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  final double animationValue;

  EnhancedUserStarPainter({
    required this.color,
    required this.glowIntensity,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Multiple glow layers for depth and prominence
    if (glowIntensity > 0) {
      // Outer glow - largest and most subtle
      final outerGlowPaint = Paint()
        ..color = color.withValues(alpha: glowIntensity * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      _drawStar(canvas, center, radius * 3.0, outerGlowPaint);

      // Middle glow - medium size
      final middleGlowPaint = Paint()
        ..color = color.withValues(alpha: glowIntensity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      _drawStar(canvas, center, radius * 2.2, middleGlowPaint);

      // Inner glow - closer to star
      final innerGlowPaint = Paint()
        ..color = color.withValues(alpha: glowIntensity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      _drawStar(canvas, center, radius * 1.5, innerGlowPaint);
    }

    // Pulsing ring effect
    final ringPaint = Paint()
      ..color = color.withValues(
        alpha:
            glowIntensity *
            0.4 *
            (0.5 + 0.5 * math.sin(animationValue * math.pi * 3)),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius * 1.2, ringPaint);

    // Secondary pulsing ring
    final ring2Paint = Paint()
      ..color = color.withValues(
        alpha:
            glowIntensity *
            0.2 *
            (0.5 + 0.5 * math.sin(animationValue * math.pi * 2 + math.pi)),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 1.4, ring2Paint);

    // Main star with gradient for depth
    final gradient = RadialGradient(
      colors: [
        color,
        color.withValues(alpha: 0.9),
        color.withValues(alpha: 0.7),
        color.withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    final starPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    _drawStar(canvas, center, radius, starPaint);

    // Enhanced outline with varying thickness
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    _drawStar(canvas, center, radius, outlinePaint);

    // Sparkle effects around the star
    final sparklePaint = Paint()
      ..color = AsteriaTheme.accentColor.withValues(alpha: 0.8);

    for (int i = 0; i < 6; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * math.pi / 3);
      final sparkleX = center.dx + (radius * 1.8) * math.cos(angle);
      final sparkleY = center.dy + (radius * 1.8) * math.sin(angle);

      final sparkleAlpha =
          0.3 + 0.7 * math.sin(animationValue * math.pi * 4 + i);
      sparklePaint.color = AsteriaTheme.accentColor.withValues(
        alpha: sparkleAlpha,
      );

      canvas.drawCircle(Offset(sparkleX, sparkleY), 2.5, sparklePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final angle = math.pi / 5; // 36 degrees for 5-pointed star

    for (int i = 0; i < 5; i++) {
      final x = center.dx + radius * math.cos(i * 2 * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * 2 * angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Inner point
      final innerX =
          center.dx +
          (radius * 0.4) * math.cos((i * 2 + 1) * angle - math.pi / 2);
      final innerY =
          center.dy +
          (radius * 0.4) * math.sin((i * 2 + 1) * angle - math.pi / 2);
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is EnhancedUserStarPainter &&
        (oldDelegate.color != color ||
            oldDelegate.glowIntensity != glowIntensity ||
            oldDelegate.animationValue != animationValue);
  }
}
