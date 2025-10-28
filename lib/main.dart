import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'background.dart';
import 'pages/auth_gate.dart';
import 'utils/constants.dart';
import 'theme.dart';
import 'services/push_service.dart';
import 'services/theme_controller.dart';

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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AsteriaTheme.lightTheme,
      darkTheme: AsteriaTheme.darkTheme,
      themeMode: ThemeController.instance.mode,
      home: const Background(child: AuthGate()),
    );
  }
}
