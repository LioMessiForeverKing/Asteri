import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'background.dart';
import 'pages/auth_gate.dart';
import 'utils/constants.dart';
import 'theme.dart';
import 'services/push_service.dart';
import 'services/notification_service.dart';
// import 'services/location_service.dart'; // Location disabled for privacy
import 'services/theme_controller.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.kSupabaseUrl,
    anonKey: AppConstants.kSupabaseAnonKey,
  );
  // Best-effort push and notification init (non-blocking)
  unawaited(PushService.instance.initialize());
  unawaited(NotificationService.instance.initialize());
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.instance.addListener(_onThemeChanged);
    // Best-effort location refresh on app start
    // Non-blocking, internally rate-limited
    // unawaited(LocationService.maybeUpdateLocation()); // Location disabled for privacy
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh location when app becomes active, rate-limited inside service
      // unawaited(LocationService.maybeUpdateLocation()); // Location disabled for privacy
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AsteriaTheme.lightTheme,
      darkTheme: AsteriaTheme.darkTheme,
      themeMode: ThemeController.instance.mode,
      home: const Background(child: AuthGate()),
    );
  }
}
