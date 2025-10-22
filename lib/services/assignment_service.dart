import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentService {
  AssignmentService._();
  static final AssignmentService instance = AssignmentService._();

  final StreamController<String> _assignmentStreamController =
      StreamController<String>.broadcast();
  RealtimeChannel? _channel;
  final Map<int, String> _roundToLabel = <int, String>{};
  int _currentRound = 1;

  Future<String> fetchCurrentTableLabel() async {
    final res = await Supabase.instance.client.functions.invoke(
      'assignment-current',
    );
    final data = res.data as Map<String, dynamic>?;
    final label = data != null ? data['table_label'] as String? : null;
    return label ?? 'X';
  }

  Future<void> initializeSchedule() async {
    final res = await Supabase.instance.client.functions.invoke('my-schedule');
    final data = res.data as Map<String, dynamic>?;
    _roundToLabel.clear();
    if (data != null) {
      final schedule = data['schedule'] as List<dynamic>?;
      final cr = data['current_round'];
      if (schedule != null) {
        for (final row in schedule) {
          if (row is Map<String, dynamic>) {
            final r = row['round'];
            final lbl = row['table_label'];
            if (r is int && lbl is String) {
              _roundToLabel[r] = lbl;
            }
          }
        }
      }
      if (cr is int) _currentRound = cr;
    }
    final current = _roundToLabel[_currentRound];
    if (current is String) {
      _assignmentStreamController.add(current);
    }
  }

  Stream<String> subscribeRoundChanges() {
    _channel ??= Supabase.instance.client.channel('round');
    _channel!.onBroadcast(
      event: 'round.changed',
      callback: (dynamic payload) {
        try {
          if (payload is Map && payload['round'] is int) {
            _currentRound = payload['round'] as int;
            final next = _roundToLabel[_currentRound];
            if (next is String && next.isNotEmpty) {
              _assignmentStreamController.add(next);
            }
          }
        } catch (_) {}
      },
    );
    _channel!.subscribe();
    return _assignmentStreamController.stream;
  }

  Future<void> dispose() async {
    await _channel?.unsubscribe();
    await _assignmentStreamController.close();
  }

  Future<void> adminSwitch({
    required String tableLabel,
    String audience = 'all',
    String? message,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'assignment-switch',
      body: {
        'table_label': tableLabel,
        'audience': audience,
        if (message != null) 'message': message,
      },
    );
  }

  Future<void> adminSwitchRound({required int round}) async {
    await Supabase.instance.client.functions.invoke(
      'round-switch',
      body: {'round': round},
    );
  }
}
