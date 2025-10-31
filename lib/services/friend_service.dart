import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';

class FriendRequest {
  final int id;
  final String senderId;
  final String receiverId;
  final String status; // pending, accepted, declined, cancelled
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> m) => FriendRequest(
        id: (m['id'] as num).toInt(),
        senderId: m['sender_id'] as String,
        receiverId: m['receiver_id'] as String,
        status: m['status'] as String,
        createdAt: DateTime.parse(m['created_at'].toString()),
      );
}

class FriendService {
  FriendService._();
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> sendRequest(String receiverUserId) async {
    final uid = _client.auth.currentUser!.id;
    if (uid == receiverUserId) return;
    await _client.from('friend_requests').insert({
      'sender_id': uid,
      'receiver_id': receiverUserId,
    });
  }

  static Future<List<FriendRequest>> incomingPending() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('friend_requests')
        .select()
        .eq('receiver_id', uid)
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List<dynamic>)
        .map((e) => FriendRequest.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<String?> accept(int requestId, String senderId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('friend_requests')
        .update({'status': 'accepted', 'responded_at': DateTime.now().toIso8601String()})
        .eq('id', requestId)
        .eq('receiver_id', uid);
    // Auto create conversation
    final cid = await ChatService.startOrGetConversationWith(senderId);
    return cid;
  }

  static Future<void> decline(int requestId) async {
    final uid = _client.auth.currentUser!.id;
    await _client
        .from('friend_requests')
        .update({'status': 'declined', 'responded_at': DateTime.now().toIso8601String()})
        .eq('id', requestId)
        .eq('receiver_id', uid);
  }
}



