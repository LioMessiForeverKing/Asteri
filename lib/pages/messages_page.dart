import 'package:flutter/material.dart';
import '../theme.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with TickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _fadeAnim;
  final TextEditingController _searchController = TextEditingController();

  final List<_Conversation> _conversations = const [
    _Conversation(
      name: 'TechReviewer',
      message: 'Hey! Just watched your latest video 🎥',
      time: '2m ago',
      avatarEmoji: '🧑🏻‍🦲',
      unread: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      duration: AsteriaTheme.animationMedium,
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _fade,
      curve: AsteriaTheme.curveElegant,
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F5F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AsteriaTheme.spacingLarge,
                  vertical: AsteriaTheme.spacingMedium,
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSearchField(context)),
                    const SizedBox(width: 12),
                    _buildComposeButton(context),
                  ],
                ),
              ),
              Container(
                height: 0.5,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE0E0E0),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final convo = _conversations[index];
                    return _ConversationTile(conversation: convo);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F1F3);
    final Color border = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 22,
            color: AsteriaTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search messages...',
                hintStyle: TextStyle(
                  color: AsteriaTheme.textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeButton(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F1F3);
    final Color border = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 22),
        color: const Color(0xFFA0522D),
        onPressed: () {},
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
        tooltip: 'New message',
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AsteriaTheme.spacingLarge,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE8E4DE),
                  child: Text(
                    conversation.avatarEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                if (conversation.unread)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B6CFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F0F0F)
                              : const Color(0xFFF8F5F0),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AsteriaTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Text(
                        conversation.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: AsteriaTheme.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: AsteriaTheme.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversation {
  final String name;
  final String message;
  final String time;
  final String avatarEmoji;
  final bool unread;
  const _Conversation({
    required this.name,
    required this.message,
    required this.time,
    required this.avatarEmoji,
    this.unread = false,
  });
}
