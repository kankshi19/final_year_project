// lib/main.dart
import 'package:flutter/material.dart';
import 'package:safety_app/theme/app_theme.dart';
import 'package:safety_app/routes/app_routes.dart';

void main() {
  runApp(SafetyCompanionApp());
}

class SafetyCompanionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
