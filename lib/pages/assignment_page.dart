import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/assignment_service.dart';
import '../theme.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  String _current = 'X';
  final List<String> _history = <String>[]; // most recent first, max 2
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await AssignmentService.instance.initializeSchedule();
    _sub = AssignmentService.instance.subscribeRoundChanges().listen(
      _applyChange,
    );
    // TEMP: print and copy JWT for testing in Supabase dashboard
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    debugPrint('JWT: $token');
    if (token != null) {
      Clipboard.setData(ClipboardData(text: token));
    }
    final first = await AssignmentService.instance.fetchCurrentTableLabel();
    _setCurrent(first, addHistory: false);
  }

  void _applyChange(String next) => _setCurrent(next, addHistory: true);

  void _setCurrent(String next, {bool addHistory = true}) {
    if (next == _current) return;
    setState(() {
      if (addHistory) {
        _history.insert(0, _current);
        if (_history.length > 2) _history.removeLast();
      }
      _current = next;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Go to Table $_current',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AsteriaTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AsteriaTheme.spacingLarge),
              if (_history.isNotEmpty)
                Text(
                  'Previously: ${_history.join(' → ')}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AsteriaTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
