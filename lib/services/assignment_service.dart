import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentService {
  AssignmentService._();
  static final AssignmentService instance = AssignmentService._();

  final StreamController<String> _assignmentStreamController =
      StreamController<String>.broadcast();
  RealtimeChannel? _channel;
  RealtimeChannel? _dbChannel;
  final Map<int, String> _roundToLabel = <int, String>{};
  int _currentRound = 1;
  Timer? _pollTimer;
  String? _lastPushedLabel;

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
      _lastPushedLabel = current;
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
              _lastPushedLabel = next;
            }
          }
        } catch (_) {}
      },
    );
    _channel!.subscribe();

    // Also listen to Postgres changes on public.current_round as a reliable fallback
    _dbChannel ??= Supabase.instance.client.channel(
      'realtime:public:current_round',
    );
    _dbChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'current_round',
      callback: (payload) {
        try {
          final newRecord = payload.newRecord as Map<String, dynamic>?;
          final r = newRecord != null ? newRecord['round'] : null;
          if (r is int) {
            _currentRound = r;
            final next = _roundToLabel[_currentRound];
            if (next is String && next.isNotEmpty) {
              _assignmentStreamController.add(next);
            }
          }
        } catch (_) {}
      },
    );
    _dbChannel!.subscribe();

    // Fallback: poll the server for current assignment every 5s
    _pollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final latest = await fetchCurrentTableLabel();
        if (latest.isNotEmpty && latest != _lastPushedLabel) {
          _assignmentStreamController.add(latest);
          _lastPushedLabel = latest;
        }
      } catch (_) {}
    });
    return _assignmentStreamController.stream;
  }

  Future<void> dispose() async {
    await _channel?.unsubscribe();
    await _dbChannel?.unsubscribe();
    await _assignmentStreamController.close();
    _pollTimer?.cancel();
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
