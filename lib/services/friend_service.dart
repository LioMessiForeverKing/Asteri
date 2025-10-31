import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';
import 'match_service.dart';
import '../models/match_candidate.dart';
import 'profile_service.dart';
import '../models/profile.dart';

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

class FriendRequestWithProfile {
  final FriendRequest request;
  final Profile? profile;
  final MatchCandidate? matchData; // Contains stars and other match info

  const FriendRequestWithProfile({
    required this.request,
    this.profile,
    this.matchData,
  });
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

  /// Fetch incoming pending friend requests with profile and match data
  static Future<List<FriendRequestWithProfile>> incomingPendingWithProfiles() async {
    final requests = await incomingPending();
    final List<FriendRequestWithProfile> result = [];

    // Get all matches to find match data for each sender
    List<MatchCandidate> allMatches = [];
    try {
      allMatches = await MatchService.fetchMatches(limit: 100);
    } catch (_) {
      // If match service fails, continue without match data
    }

    for (final request in requests) {
      // Fetch profile for the sender
      Profile? profile;
      try {
        profile = await ProfileService.getProfile(request.senderId);
      } catch (_) {
        // Continue without profile if fetch fails
      }

      // Find match data for this sender
      MatchCandidate? matchData;
      try {
        final matches = allMatches.where((m) => m.userId == request.senderId);
        if (matches.isNotEmpty) {
          matchData = matches.first;
        }
      } catch (_) {
        // No match data found, that's okay
      }

      result.add(FriendRequestWithProfile(
        request: request,
        profile: profile,
        matchData: matchData,
      ));
    }

    return result;
  }

  /// Check if two users are already friends (have an accepted friend request)
  static Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final rows = await _client
          .from('friend_requests')
          .select()
          .or('and(sender_id.eq.$userId1,receiver_id.eq.$userId2),and(sender_id.eq.$userId2,receiver_id.eq.$userId1)')
          .eq('status', 'accepted')
          .limit(1);
      return (rows as List<dynamic>).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check if there's a pending friend request between two users
  /// Returns the request if found, null otherwise
  static Future<FriendRequest?> getPendingRequest(String userId1, String userId2) async {
    try {
      final rows = await _client
          .from('friend_requests')
          .select()
          .or('and(sender_id.eq.$userId1,receiver_id.eq.$userId2),and(sender_id.eq.$userId2,receiver_id.eq.$userId1)')
          .eq('status', 'pending')
          .limit(1);
      if ((rows as List<dynamic>).isEmpty) return null;
      return FriendRequest.fromMap(Map<String, dynamic>.from(rows.first));
    } catch (_) {
      return null;
    }
  }

  /// Get all friends (accepted friend requests) with profile data
  static Future<List<FriendWithProfile>> getAllFriends() async {
    final uid = _client.auth.currentUser!.id;
    try {
      // Get all accepted friend requests where current user is either sender or receiver
      final rows = await _client
          .from('friend_requests')
          .select()
          .or('sender_id.eq.$uid,receiver_id.eq.$uid')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      final List<FriendWithProfile> friends = [];
      
      for (final row in rows as List<dynamic>) {
        final request = FriendRequest.fromMap(Map<String, dynamic>.from(row));
        // Determine the other user's ID
        final otherUserId = request.senderId == uid 
            ? request.receiverId 
            : request.senderId;
        
        // Fetch profile for the other user
        Profile? profile;
        try {
          profile = await ProfileService.getProfile(otherUserId);
        } catch (_) {
          // Continue if profile fetch fails
        }
        
        if (profile != null) {
          friends.add(FriendWithProfile(
            userId: otherUserId,
            profile: profile,
          ));
        }
      }
      
      return friends;
    } catch (_) {
      return [];
    }
  }
}

class FriendWithProfile {
  final String userId;
  final Profile profile;

  const FriendWithProfile({
    required this.userId,
    required this.profile,
  });
}



