import 'package:flutter/material.dart';
import 'package:safety_app/screens/home_screen.dart';
import 'package:safety_app/screens/emergency_contacts_screen.dart';
import 'package:safety_app/screens/safety_tips_screen.dart';
import 'package:safety_app/screens/heart_rate_monitor_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String emergencyContacts = '/emergency-contacts';
  static const String safetyTips = '/safety-tips';
  static const String heartRateMonitor = '/heart-rate-monitor';

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => HomeScreen(),
      emergencyContacts: (context) => EmergencyContactsScreen(),
      safetyTips: (context) => SafetyTipsScreen(),
      heartRateMonitor: (context) => HeartRateMonitorScreen(),
    };
  }
}
