import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationSummary {
  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String? otherAvatarUrl;
  final String lastMessage;
  final DateTime lastAt;
  final bool unread;

  const ConversationSummary({
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });
}

class ChatMessage {
  final int id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: (m['id'] as num).toInt(),
        conversationId: m['conversation_id'] as String,
        senderId: m['sender_id'] as String,
        content: m['content'] as String?,
        imageUrl: m['image_url'] as String?,
        createdAt: DateTime.parse(m['created_at'].toString()),
      );
}

class ChatService {
  ChatService._();
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> startOrGetConversationWith(String otherUserId) async {
    final uid = _client.auth.currentUser!.id;
    // Check for existing conversation with both participants
    final existing = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', uid)
        .then((rows) async {
      final ids = (rows as List<dynamic>)
          .map((e) => e['conversation_id'] as String)
          .toList();
      if (ids.isEmpty) return null;
      final hit = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .inFilter('conversation_id', ids)
          .eq('user_id', otherUserId)
          .maybeSingle();
      return hit?['conversation_id'] as String?;
    });
    if (existing != null) return existing;

    final convo = await _client
        .from('conversations')
        .insert({})
        .select('id')
        .single();
    final cid = convo['id'] as String;
    await _client.from('conversation_participants').insert([
      {'conversation_id': cid, 'user_id': uid},
      {'conversation_id': cid, 'user_id': otherUserId},
    ]);
    return cid;
  }

  static Future<void> sendMessage(
    String conversationId, {
    String? text,
    String? imageUrl,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': text,
      'image_url': imageUrl,
    });
    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }

  static Future<List<ConversationSummary>> fetchConversations() async {
    final uid = _client.auth.currentUser!.id;

    try {
      final rows = await _client.rpc('fetch_conversation_summaries', params: {
        'uid': uid,
      });

      if (rows is List<dynamic>) {
        return rows.map((e) {
          return ConversationSummary(
            conversationId: e['conversation_id'] as String,
            otherUserId: e['other_user_id'] as String,
            otherName: (e['other_name'] ?? 'User').toString(),
            otherAvatarUrl: e['other_avatar_url'] as String?,
            lastMessage: (e['last_message'] ?? '') as String,
            lastAt: DateTime.parse(e['last_at'].toString()),
            unread: (e['unread'] as bool?) ?? false,
          );
        }).toList();
      }
    } catch (_) {
      // Fallback if RPC not present: derive client-side (simple, not paginated)
    }

    // Fallback implementation
    final parts = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', uid);
    final ids = (parts as List<dynamic>)
        .map((e) => e['conversation_id'] as String)
        .toList();
    if (ids.isEmpty) return <ConversationSummary>[];
    final msgs = await _client
        .from('messages')
        .select('conversation_id, content, sender_id, created_at')
        .inFilter('conversation_id', ids)
        .order('created_at', ascending: false);
    final Map<String, dynamic> latestByConv = {};
    for (final m in msgs as List<dynamic>) {
      final cid = m['conversation_id'] as String;
      if (!latestByConv.containsKey(cid)) latestByConv[cid] = m;
    }
    final List<ConversationSummary> out = [];
    for (final cid in latestByConv.keys) {
      // Find other participant (simplified for 1:1)
      final others = await _client
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', cid)
          .neq('user_id', uid);
      final otherId = (others as List<dynamic>).first['user_id'] as String;
      final prof = await _client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', otherId)
          .maybeSingle();
      final m = latestByConv[cid] as Map<String, dynamic>;
      out.add(ConversationSummary(
        conversationId: cid,
        otherUserId: otherId,
        otherName: (prof?['full_name'] ?? 'User').toString(),
        otherAvatarUrl: prof?['avatar_url'] as String?,
        lastMessage: (m['content'] ?? '📷 Photo') as String,
        lastAt: DateTime.parse(m['created_at'].toString()),
        unread: true,
      ));
    }
    return out;
  }

  static Future<List<ChatMessage>> fetchMessages(String conversationId,
      {int limit = 50, DateTime? before}) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>)
        .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}


