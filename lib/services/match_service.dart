import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_candidate.dart';

class MatchService {
  MatchService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<MatchCandidate>> fetchMatches({int limit = 20}) async {
    final res = await _client.functions.invoke(
      'get_matches',
      method: HttpMethod.get,
      headers: {'Content-Type': 'application/json'},
      queryParameters: {'limit': '$limit'},
    );

    final body = res.data;
    if (body is Map<String, dynamic>) {
      final List<dynamic> list = body['matches'] as List<dynamic>? ?? const [];
      return list
          .map((e) => MatchCandidate.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    if (body is String && body.isNotEmpty) {
      final dynamic parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final List<dynamic> list = parsed['matches'] as List<dynamic>? ?? const [];
        return list
            .map((e) => MatchCandidate.fromMap(Map<String, dynamic>.from(e)))
            .toList(growable: false);
      }
    }
    return const [];
  }
}

