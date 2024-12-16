import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/safety_tips_screen.dart';
import '../screens/heart_rate_monitor_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => HomeScreen(),
    '/emergency': (context) => EmergencyContactsScreen(),
    '/safety-tips': (context) => SafetyTipsScreen(),
    '/heart-monitor': (context) => HeartRateMonitorScreen(),
  };
}
