import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  static Future<List<Map<String, dynamic>>> fetchMySubscriptions({
    int maxResults = 10,
  }) async {
    final accessToken = await AuthService.getGoogleAccessToken();
    if (accessToken == null) {
      throw Exception('Missing Google access token');
    }

    final uri = Uri.parse('$_baseUrl/subscriptions').replace(
      queryParameters: {
        'part': 'snippet',
        'mine': 'true',
        'maxResults': maxResults.toString(),
        // Order by relevance to show interesting channels first
        'order': 'relevance',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'YouTube API error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return items;
  }

  static Future<List<Map<String, dynamic>>> fetchMyLikedVideos({
    int maxResults = 10,
  }) async {
    final accessToken = await AuthService.getGoogleAccessToken();
    if (accessToken == null) {
      throw Exception('Missing Google access token');
    }

    // Liked videos are exposed via the special playlistId 'LL'
    final uri = Uri.parse('$_baseUrl/playlistItems').replace(
      queryParameters: {
        'part': 'snippet',
        'playlistId': 'LL',
        'maxResults': maxResults.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'YouTube API error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return items;
  }

  static Future<List<Map<String, dynamic>>> fetchAllSubscriptions({
    int pageSize = 50,
  }) async {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final accessToken = await AuthService.getGoogleAccessToken();
      if (accessToken == null) {
        throw Exception('Missing Google access token');
      }
      final uri = Uri.parse('$_baseUrl/subscriptions').replace(
        queryParameters: {
          'part': 'snippet',
          'mine': 'true',
          'maxResults': pageSize.toString(),
          if (pageToken != null) 'pageToken': pageToken,
          'order': 'relevance',
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
          'YouTube API error ${response.statusCode}: ${response.body}',
        );
      }
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      all.addAll(items);
      pageToken = decoded['nextPageToken']?.toString();
    } while (pageToken != null && pageToken.isNotEmpty);
    return all;
  }

  static Future<List<Map<String, dynamic>>> fetchAllLikedVideos({
    int pageSize = 50,
    int maxItems = 800,
  }) async {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      if (maxItems > 0 && all.length >= maxItems) break;
      final accessToken = await AuthService.getGoogleAccessToken();
      if (accessToken == null) {
        throw Exception('Missing Google access token');
      }
      int effectivePageSize = pageSize;
      if (maxItems > 0) {
        final remaining = maxItems - all.length;
        if (remaining < effectivePageSize) {
          effectivePageSize = remaining;
        }
        if (effectivePageSize <= 0) break;
      }
      final uri = Uri.parse('$_baseUrl/playlistItems').replace(
        queryParameters: {
          'part': 'snippet',
          'playlistId': 'LL',
          'maxResults': effectivePageSize.toString(),
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
          'YouTube API error ${response.statusCode}: ${response.body}',
        );
      }
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      all.addAll(items);
      pageToken = decoded['nextPageToken']?.toString();
    } while (pageToken != null && pageToken.isNotEmpty);
    return all;
  }

  static Future<int> syncSubscriptionsToSupabase({
    bool full = true,
    int maxResults = 25,
  }) async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');
    final items = full
        ? await fetchAllSubscriptions(pageSize: 50)
        : await fetchMySubscriptions(maxResults: maxResults);
    final rows = items
        .map((item) {
          final snippet =
              (item['snippet'] ?? <String, dynamic>{}) as Map<String, dynamic>;
          final resourceId =
              (snippet['resourceId'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;
          final channelId = resourceId['channelId']?.toString();
          final thumbnails =
              (snippet['thumbnails'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;
          final defaultThumb =
              (thumbnails['default'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;
          return <String, dynamic>{
            'user_id': userId,
            'channel_id': channelId,
            'title': snippet['title']?.toString(),
            'thumbnail_url': defaultThumb['url']?.toString(),
          };
        })
        .where((row) => (row['channel_id'] as String?) != null)
        .toList();

    if (rows.isEmpty) return 0;
    await Supabase.instance.client
        .from('youtube_subscriptions')
        .upsert(rows, onConflict: 'user_id,channel_id');
    return rows.length;
  }

  static Future<int> syncLikedVideosToSupabase({
    bool full = true,
    int maxResults = 25,
  }) async {
    final userId = AuthService.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');
    final items = full
        ? await fetchAllLikedVideos(pageSize: 50, maxItems: 800)
        : await fetchMyLikedVideos(maxResults: maxResults);
    final rows = items
        .map((item) {
          final snippet =
              (item['snippet'] ?? <String, dynamic>{}) as Map<String, dynamic>;
          final resourceId =
              (snippet['resourceId'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;
          final videoId = resourceId['videoId']?.toString();
          final thumbnails =
              (snippet['thumbnails'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;
          final defaultThumb =
              (thumbnails['default'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;
          return <String, dynamic>{
            'user_id': userId,
            'video_id': videoId,
            'title': snippet['title']?.toString(),
            'channel_title': snippet['channelTitle']?.toString(),
            'thumbnail_url': defaultThumb['url']?.toString(),
            'published_at': snippet['publishedAt']?.toString(),
          };
        })
        .where((row) => (row['video_id'] as String?) != null)
        .toList();

    if (rows.isEmpty) return 0;
    await Supabase.instance.client
        .from('youtube_liked_videos')
        .upsert(rows, onConflict: 'user_id,video_id');
    return rows.length;
  }
}
