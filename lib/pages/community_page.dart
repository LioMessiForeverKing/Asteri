import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import 'server_page.dart';
import '../services/profile_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;
  Map<String, String>? _profile;

  // Seed with a default Music community for now
  final List<Map<String, dynamic>> _myServers = [
    {
      'id': 'music-1',
      'name': 'Music Community',
      'description': 'Share tracks, playlists and discover new artists',
      'memberCount': 1,
      'maxMembers': 3,
      'onlineCount': 1,
      'icon': '🎵',
      'category': 'Music',
      'channels': ['general', 'introductions', 'share-music'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final local = await ProfileService.loadLocalProfile();
    if (mounted) setState(() => _profile = local);
    if (local == null) {
      final fetched = await ProfileService.fetchFromSupabaseAndCache();
      if (mounted) setState(() => _profile = fetched);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          // Paper background
          Container(decoration: AsteriaTheme.gradientOverlayDecoration()),

          // Decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(
              opacity: 0.2,
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
              opacity: 0.15,
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
            child: Column(
              children: [
                // Header (no back button)
                Padding(
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        'Community',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AsteriaTheme.primaryColor),
                      ),

                      // Logo
                      Container(
                        decoration: AsteriaTheme.paperCardDecoration(),
                        padding: const EdgeInsets.all(
                          AsteriaTheme.spacingSmall,
                        ),
                        child: SvgPicture.asset(
                          'assets/Logos/Asteri.svg',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AsteriaTheme.spacingLarge),

                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _selectedIndex == 0
                        ? _buildMyServersTab()
                        : _buildProfileTab(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Deprecated tab button removed (bottom nav used instead)

  Widget _buildBottomNav() {
    return Container(
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundPrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AsteriaTheme.spacingLarge,
        vertical: AsteriaTheme.spacingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(
            icon: Icons.groups_rounded,
            index: 0,
            tooltip: 'Communities',
          ),
          _buildNavIcon(
            icon: Icons.person_rounded,
            index: 1,
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required int index,
    required String tooltip,
  }) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => setState(() => _selectedIndex = index),
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(AsteriaTheme.spacingSmall),
        decoration: BoxDecoration(
          color: isSelected ? AsteriaTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AsteriaTheme.radiusMedium),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AsteriaTheme.textOnPrimary
              : AsteriaTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMyServersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Communities',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AsteriaTheme.primaryColor),
          ),
          const SizedBox(height: AsteriaTheme.spacingMedium),
          Text(
            'Connect with people who share your interests',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AsteriaTheme.textSecondary),
          ),
          const SizedBox(height: AsteriaTheme.spacingLarge),

          // Show empty state if no servers
          if (_myServers.isEmpty)
            _buildEmptyState(
              icon: Icons.group_add_rounded,
              title: 'No Communities Yet',
              subtitle:
                  'Your personalized communities will appear here once you\'re assigned to a cluster based on your YouTube interests.',
              actionText: 'Learn More',
              onAction: () {
                // Show info about clustering
              },
            )
          else
            ..._myServers.map(
              (server) => _buildServerCard(server, isJoined: true),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AsteriaTheme.backgroundSecondary,
                backgroundImage:
                    (_profile != null && (_profile!['photo'] ?? '').isNotEmpty)
                    ? NetworkImage(_profile!['photo']!)
                    : null,
                child: (_profile == null || (_profile!['photo'] ?? '').isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: AsteriaTheme.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: AsteriaTheme.spacingMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile != null && (_profile!['name'] ?? '').isNotEmpty
                        ? _profile!['name']!
                        : 'Your Name',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AsteriaTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _profile != null && (_profile!['email'] ?? '').isNotEmpty
                        ? _profile!['email']!
                        : 'email@example.com',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AsteriaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AsteriaTheme.spacingMedium),
          // Removed local-cache notice per request
          const SizedBox(height: AsteriaTheme.spacingMedium),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AsteriaTheme.spacingXLarge),
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundPrimary,
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AsteriaTheme.primaryColor.withValues(alpha: 0.1),
                  AsteriaTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(icon, size: 40, color: AsteriaTheme.primaryColor),
          ),

          const SizedBox(height: AsteriaTheme.spacingLarge),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AsteriaTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AsteriaTheme.spacingMedium),

          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AsteriaTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AsteriaTheme.spacingXLarge),

          // Action button
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.info_outline_rounded),
            label: Text(actionText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AsteriaTheme.primaryColor,
              foregroundColor: AsteriaTheme.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AsteriaTheme.spacingLarge,
                vertical: AsteriaTheme.spacingMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(
    Map<String, dynamic> server, {
    required bool isJoined,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AsteriaTheme.spacingMedium),
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
            child: Row(
              children: [
                // Server icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: AsteriaTheme.paperCardDecoration(
                    backgroundColor: AsteriaTheme.backgroundSecondary,
                  ),
                  child: Center(
                    child: Text(
                      server['icon'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AsteriaTheme.spacingMedium),
                // Server info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server['name'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AsteriaTheme.primaryColor),
                      ),
                      const SizedBox(height: AsteriaTheme.spacingXSmall),
                      Text(
                        server['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AsteriaTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Match score (for discover tab)
                if (!isJoined && server['matchScore'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AsteriaTheme.spacingSmall,
                      vertical: AsteriaTheme.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AsteriaTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AsteriaTheme.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '${server['matchScore']}% match',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AsteriaTheme.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AsteriaTheme.spacingLarge,
              vertical: AsteriaTheme.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AsteriaTheme.backgroundSecondary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AsteriaTheme.radiusLarge),
                bottomRight: Radius.circular(AsteriaTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 16,
                  color: AsteriaTheme.textSecondary,
                ),
                const SizedBox(width: AsteriaTheme.spacingXSmall),
                Text(
                  '${server['memberCount']} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AsteriaTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AsteriaTheme.spacingMedium),
                Icon(Icons.circle, size: 8, color: AsteriaTheme.successColor),
                const SizedBox(width: AsteriaTheme.spacingXSmall),
                Text(
                  '${server['onlineCount']} online',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AsteriaTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  server['category'],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AsteriaTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Channels (for joined servers)
          if (isJoined && server['channels'] != null)
            Padding(
              padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Channels',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AsteriaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AsteriaTheme.spacingSmall),
                  Wrap(
                    spacing: AsteriaTheme.spacingSmall,
                    runSpacing: AsteriaTheme.spacingSmall,
                    children: (server['channels'] as List<String>)
                        .map(
                          (channel) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AsteriaTheme.spacingSmall,
                              vertical: AsteriaTheme.spacingXSmall,
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
                              '#$channel',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AsteriaTheme.primaryColor),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ServerPage(server: server),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.95, end: 1.0)
                                        .animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutBack,
                                          ),
                                        ),
                                    child: child,
                                  ),
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 600),
                        ),
                      );
                    },
                    icon: Icon(
                      isJoined ? Icons.chat_rounded : Icons.add_rounded,
                    ),
                    label: Text(isJoined ? 'Open Server' : 'Join Server'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined
                          ? AsteriaTheme.primaryColor
                          : AsteriaTheme.secondaryColor,
                      foregroundColor: AsteriaTheme.textOnPrimary,
                    ),
                  ),
                ),
                if (!isJoined) ...[
                  const SizedBox(width: AsteriaTheme.spacingMedium),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Preview server
                    },
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AsteriaTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
