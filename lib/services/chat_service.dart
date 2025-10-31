import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';

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
    // debugPrint('Looking for conversation with user: $otherUserId');
    
    // First, try to get existing conversations from the fetch list
    // This is more reliable than querying directly
    try {
      final existingConvs = await fetchConversations();
      final existingWithUser = existingConvs.where((c) => c.otherUserId == otherUserId).toList();
      if (existingWithUser.isNotEmpty) {
        // Prefer the one with messages
        final withMessages = existingWithUser.where((c) => c.lastMessage != 'No messages yet').toList();
        if (withMessages.isNotEmpty) {
          final selected = withMessages.first;
          // debugPrint('Found existing conversation with messages: ${selected.conversationId}');
          return selected.conversationId;
        } else {
          final selected = existingWithUser.first;
          // debugPrint('Found existing conversation without messages: ${selected.conversationId}');
          return selected.conversationId;
        }
      }
    } catch (e) {
      debugPrint('Error fetching existing conversations: $e');
    }
    
    // Fallback: Check for existing conversation with both participants
    // Get all conversations where current user is a participant
    final userConvs = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', uid);
    
    final userConvIds = (userConvs as List<dynamic>)
        .map((e) => e['conversation_id'] as String)
        .toList();
    
    debugPrint('User is in ${userConvIds.length} conversations');
    
    if (userConvIds.isEmpty) {
      debugPrint('No existing conversations found, creating new one');
    } else {
      // Check which of these conversations also has the other user
      // Get all participants for user's conversations
      // This query should now work with the updated RLS policy
      final allParticipants = await _client
          .from('conversation_participants')
          .select('conversation_id, user_id')
          .inFilter('conversation_id', userConvIds);
      
      final allParticipantsList = allParticipants as List<dynamic>;
      debugPrint('Found ${allParticipantsList.length} participant records');
      
      if (allParticipantsList.isEmpty) {
        debugPrint('No participants found - RLS might be blocking. Check if SQL fix was applied.');
      }
      
      // Group by conversation_id to find which have both users
      final Map<String, Set<String>> convParticipants = {};
      for (final p in allParticipantsList) {
        final convId = p['conversation_id'] as String;
        final userId = p['user_id'] as String;
        convParticipants.putIfAbsent(convId, () => <String>{}).add(userId);
        // debugPrint('Conversation $convId has participant: $userId');
      }
      
      // Find conversations where both users are participants
      final sharedConvList = <Map<String, dynamic>>[];
      for (final entry in convParticipants.entries) {
        final participants = entry.value;
        // debugPrint('Conversation ${entry.key} participants: ${participants.toList()}');
        if (participants.contains(uid) && participants.contains(otherUserId)) {
          sharedConvList.add({'conversation_id': entry.key});
          // debugPrint('✓ Found shared conversation: ${entry.key} with participants: ${participants.toList()}');
        } else {
          // debugPrint('✗ Conversation ${entry.key} is NOT shared (missing one user)');
        }
      }
      
      // debugPrint('Found ${sharedConvList.length} shared conversations out of ${convParticipants.length} total');
      
      if (sharedConvList.isNotEmpty) {
        // If multiple conversations exist, find the one with messages (or the oldest one)
        debugPrint('Found ${sharedConvList.length} shared conversations, checking for messages...');
        
        // Check which conversations have messages
        final convIdsWithMessages = <String>[];
        for (final conv in sharedConvList) {
          final convId = conv['conversation_id'] as String;
          try {
            final msgCheck = await _client
                .from('messages')
                .select('id')
                .eq('conversation_id', convId)
                .limit(1)
                .maybeSingle();
            
            // If we got a result, this conversation has messages
            if (msgCheck != null) {
              convIdsWithMessages.add(convId);
              // debugPrint('Conversation $convId has messages');
            }
          } catch (e) {
            // debugPrint('Error checking messages for $convId: $e');
          }
        }
        
        // Prefer conversation with messages, otherwise use oldest (first created)
        String? selectedId;
        if (convIdsWithMessages.isNotEmpty) {
          selectedId = convIdsWithMessages.first;
          // debugPrint('Selected conversation with messages: $selectedId');
        } else {
          // No messages in any, use the first one (oldest based on creation)
          selectedId = sharedConvList.first['conversation_id'] as String;
          // debugPrint('No conversations with messages, using: $selectedId');
        }
        
        return selectedId;
      } else {
        // debugPrint('No shared conversation found, creating new one');
      }
    }

    // Create conversation first
    // Try using the security definer function first, fallback to direct insert
    String cid;
    try {
      final result = await _client.rpc('create_conversation');
      cid = result as String;
    } catch (e) {
      // Fallback to direct insert if function doesn't exist
      final convo = await _client
          .from('conversations')
          .insert({})
          .select('id')
          .single();
      cid = convo['id'] as String;
    }
    
    // Add both participants - RLS policies allow adding yourself and friends
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
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final uid = _client.auth.currentUser!.id;
    
    // Upload image if bytes provided
    String? finalImageUrl;
    if (imageBytes != null) {
      try {
        final imagePath = await uploadMessageImage(
          conversationId: conversationId,
          bytes: imageBytes,
          fileName: imageFileName,
        );
        finalImageUrl = imagePath;
      } catch (e) {
        debugPrint('Error uploading image: $e');
        throw Exception('Failed to upload image: $e');
      }
    } else {
      finalImageUrl = imageUrl;
    }
    
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': text,
      'image_url': finalImageUrl,
    });
    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }
  
  static Future<String> uploadMessageImage({
    required String conversationId,
    required Uint8List bytes,
    String? fileName,
  }) async {
    const bucket = 'message-images';
    
    // Detect content type
    final contentType = lookupMimeType(fileName ?? '', headerBytes: bytes) ?? 'image/jpeg';
    final ext = _fileExtensionForMime(contentType);
    
    // Generate unique path: messages/<conversation_id>/<timestamp>-<random>.<ext>
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = DateTime.now().microsecondsSinceEpoch.toString();
    final objectPath = 'messages/$conversationId/$timestamp-$randomId$ext';
    
    await _client.storage
        .from(bucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
    
    return objectPath;
  }
  
  static String getPublicMessageImageUrl(String objectPath) {
    const bucket = 'message-images';
    return _client.storage.from(bucket).getPublicUrl(objectPath);
  }
  
  static String _fileExtensionForMime(String? mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'image/jpeg':
      default:
        return '.jpg';
    }
  }

  static Future<List<ConversationSummary>> fetchConversations() async {
    final uid = _client.auth.currentUser!.id;

    try {
      final rows = await _client.rpc('fetch_conversation_summaries', params: {
        'uid': uid,
      });

      if (rows is List<dynamic>) {
        debugPrint('RPC returned ${rows.length} conversations');
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
    } catch (e) {
      // Fallback if RPC not present: derive client-side (simple, not paginated)
      debugPrint('RPC failed, using fallback: $e');
    }

    // Fallback implementation
    debugPrint('Using fallback to fetch conversations');
    final parts = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', uid);
    final ids = (parts as List<dynamic>)
        .map((e) => e['conversation_id'] as String)
        .toList();
    // debugPrint('Found ${ids.length} conversation participants');
    if (ids.isEmpty) {
      debugPrint('No conversation IDs found');
      return <ConversationSummary>[];
    }
    
    // Get all messages for these conversations
    final msgs = await _client
        .from('messages')
        .select('conversation_id, content, sender_id, created_at')
        .inFilter('conversation_id', ids)
        .order('created_at', ascending: false);
    // debugPrint('Found ${(msgs as List<dynamic>).length} messages');
    
    // Build map of latest message per conversation
    final Map<String, dynamic> latestByConv = {};
    for (final m in msgs as List<dynamic>) {
      final cid = m['conversation_id'] as String;
      if (!latestByConv.containsKey(cid)) {
        latestByConv[cid] = m;
        // debugPrint('Latest message in $cid: ${m['content']}');
      }
    }
    
    // Get all participants for all conversations at once to reduce queries
    final allParts = await _client
        .from('conversation_participants')
        .select('conversation_id, user_id')
        .inFilter('conversation_id', ids);
    
    // Group participants by conversation
    final Map<String, List<String>> convParticipants = {};
    for (final p in allParts as List<dynamic>) {
      final cid = p['conversation_id'] as String;
      final userId = p['user_id'] as String;
      convParticipants.putIfAbsent(cid, () => []).add(userId);
    }
    
    // Deduplicate: For each friend, only show ONE conversation (prefer one with messages)
    final Map<String, ConversationSummary> deduplicated = {};
    debugPrint('Processing ${ids.length} conversations for deduplication');
    
    for (final cid in ids) {
      // Get other participant(s) - for 1:1, there should be exactly one other
      final participants = convParticipants[cid] ?? [];
      final otherParticipants = participants.where((p) => p != uid).toList();
      
      if (otherParticipants.isEmpty) {
        // debugPrint('Skipping conversation $cid: no other participant');
        continue;
      }
      
      // For 1:1 conversations, take the first other participant
      final otherId = otherParticipants.first;
      // debugPrint('Processing conversation $cid with other user $otherId');
      
      // Get profile
      final prof = await _client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', otherId)
          .maybeSingle();
      
      // Get latest message for this conversation (if exists)
      final m = latestByConv[cid] as Map<String, dynamic>?;
      final lastMessage = m != null 
          ? (m['content'] ?? '📷 Photo') as String
          : 'No messages yet';
      final lastAt = m != null
          ? DateTime.parse(m['created_at'].toString())
          : DateTime.now();
      
      final summary = ConversationSummary(
        conversationId: cid,
        otherUserId: otherId,
        otherName: (prof?['full_name'] ?? 'User').toString(),
        otherAvatarUrl: prof?['avatar_url'] as String?,
        lastMessage: lastMessage,
        lastAt: lastAt,
        unread: true,
      );
      
      // Deduplicate by otherUserId - ALWAYS prefer conversations with messages
      final hasMessages = m != null;
      if (!deduplicated.containsKey(otherId)) {
        deduplicated[otherId] = summary;
        // debugPrint('Adding conversation $cid for user $otherId (hasMessages: $hasMessages)');
      } else {
        final existing = deduplicated[otherId]!;
        final existingHasMessages = existing.lastMessage != 'No messages yet';
        
        // Priority: 1) Messages > No messages, 2) If both same type, prefer newer
        if (hasMessages && !existingHasMessages) {
          // This one has messages, existing doesn't - always replace
          deduplicated[otherId] = summary;
          // debugPrint('✓ Replacing conversation ${existing.conversationId} with $cid (this has messages)');
        } else if (!hasMessages && existingHasMessages) {
          // Existing has messages, this one doesn't - keep existing
          // debugPrint('✗ Keeping conversation ${existing.conversationId} (has messages), skipping $cid');
        } else if (lastAt.isAfter(existing.lastAt)) {
          // Both have same message status, prefer newer one
          deduplicated[otherId] = summary;
          // debugPrint('✓ Replacing conversation ${existing.conversationId} with $cid (newer)');
        } else {
          // debugPrint('✗ Keeping existing conversation ${existing.conversationId}, skipping $cid');
        }
      }
    }
    
    final out = deduplicated.values.toList();
    // debugPrint('Returning ${out.length} deduplicated conversation summaries (was ${ids.length})');
    return out;
  }

  static Future<List<ChatMessage>> fetchMessages(String conversationId,
      {int limit = 50, DateTime? before}) async {
    try {
      // debugPrint('Fetching messages for conversation: $conversationId');
      
      // First verify we're a participant
      final uid = _client.auth.currentUser!.id;
      final participantCheck = await _client
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .eq('user_id', uid)
          .maybeSingle();
      
      if (participantCheck == null) {
        // debugPrint('User $uid is not a participant in conversation $conversationId');
        return [];
      }
      
      debugPrint('User is a participant, fetching messages...');
      
      // Previously used for debugging - removed for security
      
      final rows = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      // debugPrint('Raw query returned ${(rows as List<dynamic>).length} rows for conversation $conversationId');
      
      final messages = (rows as List<dynamic>)
          .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      
      // debugPrint('Fetched ${messages.length} messages for conversation $conversationId');
      if (messages.isEmpty && (rows as List<dynamic>).isNotEmpty) {
        // debugPrint('WARNING: Rows returned but no messages parsed. First row: ${rows.first}');
      }
      return messages;
    } catch (e, stackTrace) {
      debugPrint('Error fetching messages: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}


