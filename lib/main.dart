import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/theme/app_theme.dart';
import 'package:safety_app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'theme/theme_provider.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager().registerPeriodicTask(
      "safety-tips-task",
      "showSafetyTipTask",
      frequency: const Duration(minutes: 45), // Changed to 20 minutes
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  
  // Initialize services
  await BackgroundService.initializeService();
  await Firebase.initializeApp();

  // Get the saved preferences
  final prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
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

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "showSafetyTipTask") {
      await NotificationService.showSafetyTipNotification(); // Call random safety tip
    }
    return Future.value(true);
  });
}
class SafetyCompanionApp extends StatelessWidget {
  final bool isDarkMode;
  final bool isFirstTime;

  const SafetyCompanionApp({
    Key? key,
    required this.isDarkMode,
    required this.isFirstTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}