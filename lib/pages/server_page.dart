import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/profile_service.dart';

class ServerPage extends StatefulWidget {
  final Map<String, dynamic> server;

  const ServerPage({super.key, required this.server});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  String _selectedChannel = 'general';
  bool _showChannelsOverlay = false;
  final TextEditingController _messageController = TextEditingController();
  Map<String, String>? _profile;

  // Local-only messages; start empty so only the current user chats
  final Map<String, List<Map<String, dynamic>>> _messages = {
    'general': [],
    'introductions': [],
    'share-music': [],
  };

  // Exactly 3 users: Ayen (you) + 2 inactive placeholders
  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Ayen',
      'photo': 'https://i.pravatar.cc/150?img=1',
      'status': 'online',
      'interests': ['Music', 'Tech'],
      'lastSeen': 'online now',
    },
    {
      'name': 'Mika',
      'photo': 'https://i.pravatar.cc/150?img=12',
      'status': 'offline',
      'interests': ['Music'],
      'lastSeen': 'inactive',
    },
    {
      'name': 'Liam',
      'photo': 'https://i.pravatar.cc/150?img=22',
      'status': 'offline',
      'interests': ['Music'],
      'lastSeen': 'inactive',
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _slideController.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _slideController.dispose();
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
      body: Stack(
        children: [
          // Paper background
          Container(decoration: AsteriaTheme.gradientOverlayDecoration()),

          // Main content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Content
                  Expanded(
                    child: Stack(
                      children: [
                        // Main content area
                        _buildMainContent(),

                        // Channels overlay
                        if (_showChannelsOverlay) _buildChannelsOverlay(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundPrimary,
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: AsteriaTheme.paperCardDecoration(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AsteriaTheme.primaryColor,
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(width: AsteriaTheme.spacingMedium),

          // Server info
          Container(
            width: 40,
            height: 40,
            decoration: AsteriaTheme.paperCardDecoration(
              backgroundColor: AsteriaTheme.backgroundSecondary,
            ),
            child: Center(
              child: Text(
                widget.server['icon'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: AsteriaTheme.spacingMedium),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.server['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AsteriaTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '1/3 users • 1 online',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AsteriaTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AsteriaTheme.spacingSmall),

          // Server settings
          Container(
            decoration: AsteriaTheme.paperCardDecoration(),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: AsteriaTheme.primaryColor,
              onPressed: () {
                // Server settings
              },
              tooltip: 'Server Settings',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundPrimary,
      ),
      child: Column(
        children: [
          // Server info and channels button
          Container(
            padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
            decoration: BoxDecoration(
              color: AsteriaTheme.backgroundSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AsteriaTheme.radiusLarge),
                topRight: Radius.circular(AsteriaTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                // Server icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: AsteriaTheme.paperCardDecoration(
                    backgroundColor: AsteriaTheme.backgroundPrimary,
                  ),
                  child: Center(
                    child: Text(
                      widget.server['icon'],
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
                        widget.server['name'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AsteriaTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AsteriaTheme.spacingXSmall),
                      Text(
                        widget.server['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AsteriaTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AsteriaTheme.spacingMedium),

                // Channels button
                Container(
                  decoration: AsteriaTheme.paperCardDecoration(),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showChannelsOverlay = true;
                      });
                    },
                    icon: const Icon(Icons.list_rounded),
                    label: const Text('Channels'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsteriaTheme.primaryColor,
                      foregroundColor: AsteriaTheme.textOnPrimary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages + input
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChannelsOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: AsteriaTheme.elevatedPaperDecoration(
            backgroundColor: AsteriaTheme.backgroundPrimary,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                decoration: BoxDecoration(
                  color: AsteriaTheme.backgroundSecondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AsteriaTheme.radiusLarge),
                    topRight: Radius.circular(AsteriaTheme.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Channels',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AsteriaTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showChannelsOverlay = false;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                      color: AsteriaTheme.primaryColor,
                    ),
                  ],
                ),
              ),

              // Channels list
              Expanded(child: _buildChannelsSection()),
              const SizedBox(height: AsteriaTheme.spacingMedium),
              // Members inside overlay
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AsteriaTheme.spacingLarge,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Members',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AsteriaTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final m = _members[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(
                        right: AsteriaTheme.spacingMedium,
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(
                                  m['photo'] ??
                                      'https://i.pravatar.cc/150?img=${index + 3}',
                                ),
                                backgroundColor:
                                    AsteriaTheme.backgroundSecondary,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(m['status']),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AsteriaTheme.backgroundPrimary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AsteriaTheme.spacingSmall),
                          Text(
                            m['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelsSection() {
    final channels = widget.server['channels'] as List<String>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(AsteriaTheme.spacingMedium),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = _selectedChannel == channel;

        return Container(
          margin: const EdgeInsets.only(bottom: AsteriaTheme.spacingSmall),
          decoration: BoxDecoration(
            color: isSelected
                ? AsteriaTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AsteriaTheme.radiusMedium),
            border: isSelected
                ? Border.all(color: AsteriaTheme.primaryColor, width: 2)
                : null,
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AsteriaTheme.primaryColor
                    : AsteriaTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(AsteriaTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  '#',
                  style: TextStyle(
                    color: isSelected
                        ? AsteriaTheme.textOnPrimary
                        : AsteriaTheme.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            title: Text(
              channel,
              style: TextStyle(
                color: isSelected
                    ? AsteriaTheme.primaryColor
                    : AsteriaTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${_messages[channel]?.length ?? 0} messages',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AsteriaTheme.textTertiary),
            ),
            onTap: () {
              setState(() {
                _selectedChannel = channel;
                _showChannelsOverlay = false;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.only(bottom: AsteriaTheme.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    (message['photo'] != null &&
                        (message['photo'] as String).isNotEmpty)
                    ? NetworkImage(message['photo'] as String)
                    : null,
                backgroundColor: AsteriaTheme.backgroundSecondary,
                child:
                    (message['photo'] == null ||
                        (message['photo'] as String).isEmpty)
                    ? const Icon(
                        Icons.person_rounded,
                        color: AsteriaTheme.textSecondary,
                      )
                    : null,
              ),
              if (message['isOnline'])
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AsteriaTheme.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AsteriaTheme.backgroundPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: AsteriaTheme.spacingMedium),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message['user'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AsteriaTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AsteriaTheme.spacingSmall),
                    Text(
                      message['timestamp'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AsteriaTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AsteriaTheme.spacingXSmall),
                Text(
                  message['message'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AsteriaTheme.textPrimary,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final list = _messages[_selectedChannel] ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildMessageCard(list[index]),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message #$_selectedChannel',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AsteriaTheme.spacingSmall),
          ElevatedButton(
            onPressed: _sendMessage,
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final newMsg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user': (_profile != null && (_profile!['name'] ?? '').isNotEmpty)
          ? _profile!['name']!
          : 'You',
      'photo': (_profile != null && (_profile!['photo'] ?? '').isNotEmpty)
          ? _profile!['photo']!
          : null,
      'message': text,
      'timestamp': 'just now',
      'isOnline': true,
    };
    setState(() {
      _messages[_selectedChannel] = [
        ...(_messages[_selectedChannel] ?? []),
        newMsg,
      ];
      _messageController.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return AsteriaTheme.successColor;
      case 'away':
        return AsteriaTheme.warningColor;
      case 'busy':
        return AsteriaTheme.errorColor;
      default:
        return AsteriaTheme.textTertiary;
    }
  }

  // Reserved for future member profile interactions
}
