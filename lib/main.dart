import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'background.dart';
import 'pages/home_page.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConstants.kSupabaseUrl, anonKey: AppConstants.kSupabaseAnonKey);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Background(child: HomePage()),
    );
  }
}
