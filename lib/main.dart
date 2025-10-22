import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'background.dart';
import 'pages/auth_gate.dart';
import 'utils/constants.dart';
import 'theme.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.kSupabaseUrl,
    anonKey: AppConstants.kSupabaseAnonKey,
  );
  // Best-effort push init (non-blocking)
  unawaited(PushService.instance.initialize());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AsteriaTheme.lightTheme,
      home: const Background(child: AuthGate()),
    );
  }
}
