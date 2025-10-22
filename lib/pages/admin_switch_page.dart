import 'package:flutter/material.dart';
import '../services/assignment_service.dart';
import '../theme.dart';

class AdminSwitchPage extends StatefulWidget {
  const AdminSwitchPage({super.key});

  @override
  State<AdminSwitchPage> createState() => _AdminSwitchPageState();
}

class _AdminSwitchPageState extends State<AdminSwitchPage> {
  String _audience = 'all';
  String _message = '';
  bool _busy = false;

  Future<void> _send(String label) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AssignmentService.instance.adminSwitch(
        tableLabel: label,
        audience: _audience,
        message: _message.isEmpty ? null : _message,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Switch sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendRound(int round) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AssignmentService.instance.adminSwitchRound(round: round);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Round $round started')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Switch')),
      body: Padding(
        padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Optional message'),
              onChanged: (v) => _message = v,
            ),
            const SizedBox(height: AsteriaTheme.spacingLarge),
            DropdownButton<String>(
              value: _audience,
              items: const [DropdownMenuItem(value: 'all', child: Text('All'))],
              onChanged: (v) => setState(() => _audience = v ?? 'all'),
            ),
            const SizedBox(height: AsteriaTheme.spacingLarge),
            Wrap(
              spacing: AsteriaTheme.spacingMedium,
              children: [
                for (final label in ['X', 'Y', 'Z'])
                  ElevatedButton(
                    onPressed: _busy ? null : () => _send(label),
                    child: Text('Send $label'),
                  ),
              ],
            ),
            const SizedBox(height: AsteriaTheme.spacingLarge),
            const Text('Rounds'),
            Wrap(
              spacing: AsteriaTheme.spacingMedium,
              children: [
                for (final r in [1, 2, 3])
                  ElevatedButton(
                    onPressed: _busy ? null : () => _sendRound(r),
                    child: Text('Start Round $r'),
                  ),
              ],
            ),
            const SizedBox(height: AsteriaTheme.spacingLarge),
            const Text(
              'Note: Server enforces admin; UI is for convenience only.',
            ),
          ],
        ),
      ),
    );
  }
}
