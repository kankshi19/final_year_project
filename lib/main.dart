import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/theme/app_theme.dart';
import 'package:safety_app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Get the saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
   // Default to light theme

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: SafetyCompanionApp(isDarkMode: isDarkMode),
    ),
  );
}

class SafetyCompanionApp extends StatelessWidget {
  final bool isDarkMode;

  SafetyCompanionApp({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Set theme mode based on user preference
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
