import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class StarMapPage extends StatefulWidget {
  const StarMapPage({super.key});

  @override
  State<StarMapPage> createState() => _StarMapPageState();
}

class _StarMapPageState extends State<StarMapPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _spinAnimation;

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
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    StarData(
      id: 'star1',
      name: 'Alex',
      x: 0.3,
      y: 0.4,
      isCurrentUser: false,
      interests: ['Music', 'Gaming', 'Photography'],
      similarity: 0.85,
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
    ),
    StarData(
      id: 'star2',
      name: 'Sam',
      x: 0.7,
      y: 0.3,
      isCurrentUser: false,
      interests: ['Technology', 'Science', 'Books'],
      similarity: 0.78,
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
    ),
    StarData(
      id: 'star3',
      name: 'Jordan',
      x: 0.2,
      y: 0.7,
      isCurrentUser: false,
      interests: ['Art', 'Design', 'Music'],
      similarity: 0.92,
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
    ),
    StarData(
      id: 'star4',
      name: 'Casey',
      x: 0.8,
      y: 0.6,
      isCurrentUser: false,
      interests: ['Sports', 'Fitness', 'Travel'],
      similarity: 0.45,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    StarData(
      id: 'star5',
      name: 'Riley',
      x: 0.4,
      y: 0.2,
      isCurrentUser: false,
      interests: ['Music', 'Movies', 'Cooking'],
      similarity: 0.67,
      avatarUrl: 'https://i.pravatar.cc/150?img=6',
    ),
    StarData(
      id: 'star6',
      name: 'Morgan',
      x: 0.6,
      y: 0.8,
      isCurrentUser: false,
      interests: ['Technology', 'Gaming', 'Music'],
      similarity: 0.73,
      avatarUrl: 'https://i.pravatar.cc/150?img=7',
    ),
    StarData(
      id: 'star7',
      name: 'Taylor',
      x: 0.1,
      y: 0.5,
      isCurrentUser: false,
      interests: ['Art', 'Photography', 'Travel'],
      similarity: 0.58,
      avatarUrl: 'https://i.pravatar.cc/150?img=8',
    ),
    StarData(
      id: 'star8',
      name: 'Avery',
      x: 0.9,
      y: 0.4,
      isCurrentUser: false,
      interests: ['Science', 'Books', 'Technology'],
      similarity: 0.69,
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
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
      avatarUrl: 'https://i.pravatar.cc/150?img=10',
    ),
    StarData(
      id: 'star10',
      name: 'Cameron',
      x: 0.85,
      y: 0.8,
      isCurrentUser: false,
      interests: ['Science', 'Technology', 'Innovation'],
      similarity: 0.82,
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
    ),
    StarData(
      id: 'star11',
      name: 'Drew',
      x: 0.1,
      y: 0.8,
      isCurrentUser: false,
      interests: ['Music', 'Writing', 'Poetry'],
      similarity: 0.64,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    StarData(
      id: 'star12',
      name: 'Emery',
      x: 0.9,
      y: 0.2,
      isCurrentUser: false,
      interests: ['Business', 'Finance', 'Leadership'],
      similarity: 0.38,
      avatarUrl: 'https://i.pravatar.cc/150?img=13',
    ),
    StarData(
      id: 'star13',
      name: 'Finley',
      x: 0.25,
      y: 0.9,
      isCurrentUser: false,
      interests: ['Nature', 'Hiking', 'Photography'],
      similarity: 0.71,
      avatarUrl: 'https://i.pravatar.cc/150?img=14',
    ),
    StarData(
      id: 'star14',
      name: 'Gray',
      x: 0.75,
      y: 0.1,
      isCurrentUser: false,
      interests: ['Gaming', 'Streaming', 'Entertainment'],
      similarity: 0.55,
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
    ),
    StarData(
      id: 'star15',
      name: 'Harper',
      x: 0.05,
      y: 0.3,
      isCurrentUser: false,
      interests: ['Education', 'Teaching', 'Learning'],
      similarity: 0.61,
      avatarUrl: 'https://i.pravatar.cc/150?img=16',
    ),
    StarData(
      id: 'star16',
      name: 'Indigo',
      x: 0.95,
      y: 0.7,
      isCurrentUser: false,
      interests: ['Fashion', 'Beauty', 'Lifestyle'],
      similarity: 0.43,
      avatarUrl: 'https://i.pravatar.cc/150?img=17',
    ),
  ];

  StarData? _selectedStar;
  // Deprecated: inline profile card is now used for all stars
  // bool _showConversationCard = false;
  bool _showProfileCard = false;
  bool _showFilter = false;
  double _radiusThreshold = 240.0;
  double _similarityMin = 0.0;

  // Current user's visual settings
  Color _userStarColor = AsteriaTheme.accentColor;
  RealtimeChannel? _profileChannel;

  // Zoom and pan state (InteractiveViewer)
  late TransformationController _transformController;
  Offset? _doubleTapPosition;

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

    _transformController = TransformationController();

    _spinController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _spinAnimation = Tween<double>(begin: 0.0, end: -math.pi).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    _loadCurrentUserProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    _transformController.dispose();
    if (_profileChannel != null) {
      Supabase.instance.client.removeChannel(_profileChannel!);
    }
    super.dispose();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await ProfileService.getProfile(userId);
      if (profile == null) return;

      // Update star color
      final color = _parseHexColor(profile.starColor);

      // Compute avatar URL if stored as storage path
      final String? avatarUrl =
          (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
          ? null
          : ProfileService.getPublicAvatarUrl(profile.avatarUrl!);

      // Replace the current user star entry (index 0)
      if (_stars.isNotEmpty && _stars.first.isCurrentUser) {
        _stars[0] = StarData(
          id: 'you',
          name: profile.fullName.isNotEmpty ? profile.fullName : 'You',
          x: _stars[0].x,
          y: _stars[0].y,
          isCurrentUser: true,
          interests: _stars[0].interests,
          similarity: 1.0,
          avatarUrl: avatarUrl ?? _stars[0].avatarUrl,
        );
      }

      if (mounted) {
        setState(() {
          _userStarColor = color;
        });
      }

      // Subscribe to realtime profile changes to reflect star color updates
      _profileChannel ??= Supabase.instance.client
          .channel('profile-changes-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'profiles',
            callback: (payload) {
              final Map<String, dynamic>? newRecord =
                  payload.newRecord as Map<String, dynamic>?;
              if (newRecord == null) return;
              if (newRecord['id'] != userId) return;
              final String? newColorHex = newRecord['star_color'] as String?;
              final String? newName = newRecord['full_name'] as String?;
              final String? newAvatarPath = newRecord['avatar_url'] as String?;
              final Color? newColor = newColorHex != null
                  ? _parseHexColor(newColorHex)
                  : null;
              final String? newAvatarUrl =
                  (newAvatarPath == null || newAvatarPath.isEmpty)
                  ? null
                  : ProfileService.getPublicAvatarUrl(newAvatarPath);
              if (!mounted) return;
              setState(() {
                if (newColor != null) _userStarColor = newColor;
                if (_stars.isNotEmpty && _stars.first.isCurrentUser) {
                  _stars[0] = StarData(
                    id: 'you',
                    name: (newName != null && newName.isNotEmpty)
                        ? newName
                        : _stars[0].name,
                    x: _stars[0].x,
                    y: _stars[0].y,
                    isCurrentUser: true,
                    interests: _stars[0].interests,
                    similarity: 1.0,
                    avatarUrl: newAvatarUrl ?? _stars[0].avatarUrl,
                  );
                }
              });
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'profiles',
            callback: (payload) {
              final Map<String, dynamic>? newRecord =
                  payload.newRecord as Map<String, dynamic>?;
              if (newRecord == null) return;
              if (newRecord['id'] != userId) return;
              final String? newColorHex = newRecord['star_color'] as String?;
              if (newColorHex != null) {
                final color = _parseHexColor(newColorHex);
                if (!mounted) return;
                setState(() => _userStarColor = color);
              }
            },
          )
          .subscribe();
    } catch (_) {
      // Non-fatal; fall back to defaults
    }
  }

  Color _parseHexColor(String hex) {
    var value = hex.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 3) {
      value = value.split('').map((c) => '$c$c').join();
    }
    final intColor = int.tryParse(value, radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | intColor);
  }

  void _onStarTap(StarData star) {
    _spinController.stop();

    setState(() {
      _selectedStar = star;
      _showProfileCard = false;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Defer spin start to next frame so selected star is rebuilt before animating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _spinController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _showProfileCard = true; // Use unified inline card for all stars
        });
      });
    });
  }

  // Legacy close for old conversation card (no longer used)
  void _closeConversationCard() {}

  void _closeProfileCard() {
    setState(() {
      _showProfileCard = false;
      _selectedStar = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(color: Theme.of(context).scaffoldBackgroundColor),

          // Main content (header removed)
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildStarMap(),
                  ),
                ),
              ],
            ),
          ),

          // Profile card for current user (non-modal)
          if (_showProfileCard && _selectedStar != null) _buildProfileCard(),

          // Top-right filter button and panel
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: Theme.of(context).brightness == Brightness.dark
                                ? 0.45
                                : 0.15,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                      onPressed: () {
                        setState(() => _showFilter = !_showFilter);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_showFilter)
                    Container(
                      width: 240,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AsteriaTheme.radiusMedium),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: Theme.of(context).brightness == Brightness.dark
                                  ? 0.35
                                  : 0.1,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Radius',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveTrackColor: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.25),
                              thumbColor:
                                  Theme.of(context).colorScheme.primary,
                              overlayColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                            ),
                            child: Slider(
                              value: _radiusThreshold,
                              min: 80,
                              max: 420,
                              onChanged: (v) => setState(() {
                                _radiusThreshold = v;
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Similarity',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveTrackColor: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.25),
                              thumbColor:
                                  Theme.of(context).colorScheme.primary,
                              overlayColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                            ),
                            child: Slider(
                              value: _similarityMin,
                              min: 0.0,
                              max: 1.0,
                              divisions: 20,
                              onChanged: (v) => setState(() {
                                _similarityMin = v;
                              }),
                            ),
                          ),
                        ],
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

  // Legacy header removed

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
      0.3,
      1.0,
    );

    final mapWidth = screenSize.width * 2;
    final mapHeight = screenSize.height * 2;

    return GestureDetector(
      onTap: _closeConversationCard,
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: () {
        final tapPos =
            _doubleTapPosition ??
            Offset(screenSize.width / 2, screenSize.height / 2);
        final scenePoint = _transformController.toScene(tapPos);
        final currentScale = _transformController.value.getMaxScaleOnAxis();
        final targetScale = currentScale < 2.0
            ? (currentScale * 1.5).clamp(0.3, 3.0)
            : 1.0;
        final scaleFactor = targetScale / currentScale;

        final Matrix4 newMatrix = _transformController.value.clone()
          ..translateByVector3(vm.Vector3(-scenePoint.dx, -scenePoint.dy, 0.0))
          ..scaleByVector3(vm.Vector3(scaleFactor, scaleFactor, 1.0))
          ..translateByVector3(vm.Vector3(scenePoint.dx, scenePoint.dy, 0.0));

        _transformController.value = newMatrix;
      },
      child: InteractiveViewer(
        transformationController: _transformController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(200),
        minScale: minScale.toDouble(),
        maxScale: 3.0,
        child: SizedBox(
          width: mapWidth,
          height: mapHeight,
          child: Stack(
            children: [
              _buildConnectionsLayer(mapWidth, mapHeight),
              ..._visibleStars().map((star) => _buildStar(star)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionsLayer(double mapWidth, double mapHeight) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color lineColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);
    return Positioned.fill(
      child: CustomPaint(
        painter: ConnectionsPainter(
          stars: _visibleStars(),
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          threshold: _radiusThreshold,
          lineColor: lineColor,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_selectedStar == null) return const SizedBox.shrink();

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.all(AsteriaTheme.spacingLarge),
          padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: AsteriaTheme.elevatedCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AsteriaTheme.accentColor,
                    backgroundImage: _selectedStar!.avatarUrl != null
                        ? NetworkImage(_selectedStar!.avatarUrl!)
                        : null,
                    child: _selectedStar!.avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AsteriaTheme.secondaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: AsteriaTheme.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedStar!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_selectedStar!.isCurrentUser)
                          Text(
                            'You',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AsteriaTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeProfileCard,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AsteriaTheme.spacingMedium),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AsteriaTheme.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: AsteriaTheme.spacingSmall),
                  Text(
                    'Interests:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AsteriaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AsteriaTheme.spacingSmall),
              Wrap(
                spacing: AsteriaTheme.spacingSmall,
                runSpacing: AsteriaTheme.spacingSmall,
                children: _selectedStar!.interests
                    .map(
                      (interest) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AsteriaTheme.spacingMedium,
                          vertical: AsteriaTheme.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: AsteriaTheme.accentDark,
                          borderRadius: BorderRadius.circular(
                            AsteriaTheme.radiusSmall,
                          ),
                        ),
                        child: Text(
                          interest,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<StarData> _visibleStars() {
    return _stars
        .where((s) => s.isCurrentUser || s.similarity >= _similarityMin)
        .toList(growable: false);
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
          animation: Listenable.merge([
            _fadeController,
            _pulseController,
            _spinController,
          ]),
          builder: (context, child) {
            final bool isTapped = _selectedStar?.id == star.id;
            return Transform.rotate(
              angle: isTapped ? _spinAnimation.value : 0.0,
              child: Transform.scale(
                scale: star.isCurrentUser
                    ? 1.0 + (_pulseAnimation.value * 0.2)
                    : 1.0,
                child: SvgPicture.asset(
                  'assets/Logos/star.svg',
                  width: star.isCurrentUser ? 60 : 40,
                  height: star.isCurrentUser ? 60 : 40,
                  colorFilter: ColorFilter.mode(
                    star.isCurrentUser
                        ? _userStarColor
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Legacy conversation card removed in favor of unified inline card

  // Legacy conversation starters retained for reference (unused)
}

class StarData {
  final String id;
  final String name;
  final double x;
  final double y;
  final bool isCurrentUser;
  final List<String> interests;
  final double similarity;
  final String? avatarUrl;

  StarData({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.isCurrentUser,
    required this.interests,
    required this.similarity,
    this.avatarUrl,
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
    // No-op: grid background replaced by ConnectionsPainter
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

class ConnectionsPainter extends CustomPainter {
  final List<StarData> stars;
  final double mapWidth;
  final double mapHeight;
  final double threshold;
  final Color? lineColor;

  ConnectionsPainter({
    required this.stars,
    required this.mapWidth,
    required this.mapHeight,
    this.threshold = 240.0,
    this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stars.isEmpty) return;

    final paint = Paint()
      ..color = (lineColor ?? Colors.black.withValues(alpha: 0.06))
      ..strokeWidth = 1.0;

    final points = stars
        .map((s) => Offset(s.x * mapWidth, s.y * mapHeight))
        .toList(growable: false);

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final p1 = points[i];
        final p2 = points[j];
        final dx = p1.dx - p2.dx;
        final dy = p1.dy - p2.dy;
        final dist2 = dx * dx + dy * dy;
        if (dist2 < threshold * threshold) {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter oldDelegate) {
    return oldDelegate.stars != stars ||
        oldDelegate.mapWidth != mapWidth ||
        oldDelegate.mapHeight != mapHeight ||
        oldDelegate.threshold != threshold ||
        oldDelegate.lineColor != lineColor;
  }
}
