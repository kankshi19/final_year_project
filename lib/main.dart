import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/theme/app_theme.dart';
import 'package:safety_app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'services/background_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.initializeService(); // Start background location service
  await Firebase.initializeApp();
  
  // Get the saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  // Check if it's the first time the app is launched
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;



  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: SafetyCompanionApp(
        isDarkMode: isDarkMode,
        isFirstTime: isFirstTime,
      ),
    ),
  );
}

class SafetyCompanionApp extends StatelessWidget {
  final bool isDarkMode;
  final bool isFirstTime;

  SafetyCompanionApp({
    required this.isDarkMode, 
    required this.isFirstTime,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, 
      initialRoute: AppRoutes.home, // Always start with SplashScreen
      routes: AppRoutes.routes, 
    );
  }
}