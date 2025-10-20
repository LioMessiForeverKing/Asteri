import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/passion_graph.dart';

class OpenAIService {
  // Calls a Supabase Edge Function to proxy OpenAI calls server-side
  // to avoid exposing API keys in the client.
  static Future<GraphSnapshot> summarizePassions({
    required List<Map<String, dynamic>> subscriptions,
    required List<Map<String, dynamic>> likedVideos,
  }) async {
    final res = await Supabase.instance.client.functions.invoke(
      'summarize_passions',
      body: <String, dynamic>{
        'subscriptions': subscriptions,
        'likedVideos': likedVideos,
        'model': 'gpt-4.1-nano',
      },
    );

    final data = (res.data ?? <String, dynamic>{}) as Map<String, dynamic>;
    // If function returns raw JSON string, parse it
    final dynamic payload = data['graph'] ?? data;
    final Map<String, dynamic> jsonMap = payload is String
        ? json.decode(payload) as Map<String, dynamic>
        : (payload as Map<String, dynamic>);
    return GraphSnapshot.fromJson(jsonMap);
  }
}
