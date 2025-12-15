import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'login_page.dart';
import 'splash_screen.dart'; // Import the splash screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hrmnonogscrrfwvxmxur.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhybW5vbm9nc2NycmZ3dnhteHVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMjk2MjIsImV4cCI6MjA4MDYwNTYyMn0.0YnF9amfp6a2XuFyHbcd_vzmimjeGOaFjHbJDAZpsyU',
  );

  runApp(const DevDeckApp());
}

class DevDeckApp extends StatelessWidget {
  const DevDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    // LISTEN TO ALL THEME CHANGES
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppTheme.isDarkNotifier,
        AppTheme.fontFamilyNotifier,
        AppTheme.fontScaleNotifier
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: 'DevDeck',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.isDarkNotifier.value
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          home: const SplashScreen(), // Changed from LoginPage to SplashScreen
        );
      },
    );
  }
}
