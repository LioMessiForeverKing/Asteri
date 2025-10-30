import 'package:flutter/material.dart';
import '../theme.dart';
import 'thread_page.dart';
import '../services/friend_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';

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

  List<ConversationSummary> _conversations = const [];

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
    _loadConversations();
    // Realtime: listen to new messages in any conversation the user is part of
    Supabase.instance.client
        .channel('messages-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadConversations(),
        )
        .subscribe();
  }
  Future<void> _loadConversations() async {
    try {
      final data = await ChatService.fetchConversations();
      if (!mounted) return;
      setState(() => _conversations = data);
    } catch (_) {
      // ignore errors for now
    }
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
                child: _conversations.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet — start a conversation from the Star Map',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AsteriaTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
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
        icon: const Icon(Icons.group_add_rounded, size: 22),
        color: const Color(0xFFA0522D),
        onPressed: () => _showFriendRequestsModal(context),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
        tooltip: 'Friend requests',
      ),
    );
  }

  void _showFriendRequestsModal(BuildContext context) async {
    final requests = await FriendService.incomingPending();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No friend requests right now',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (ctx, i) {
            final r = requests[i];
            return Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(child: Text('New request from ${r.senderId.substring(0, 6)}…')),
                TextButton(
                  onPressed: () async {
                    final cid = await FriendService.accept(r.id, r.senderId);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    if (cid != null && mounted) {
                      Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (_) => ThreadPage(
                            conversationId: cid,
                            title: 'New chat',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await FriendService.decline(r.id);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Decline'),
                ),
              ],
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: requests.length,
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ThreadPage(
              conversationId: conversation.conversationId,
              title: conversation.otherName,
            ),
          ),
        );
      },
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
                  backgroundImage: (conversation.otherAvatarUrl != null &&
                          conversation.otherAvatarUrl!.isNotEmpty)
                      ? NetworkImage(conversation.otherAvatarUrl!)
                      : null,
                  child: (conversation.otherAvatarUrl == null ||
                          conversation.otherAvatarUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
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
                          conversation.otherName,
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
                        _formatTime(conversation.lastAt),
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
                    conversation.lastMessage,
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
  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${t.month}/${t.day}';
  }
}

