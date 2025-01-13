import 'package:flutter/material.dart';
import 'package:safety_app/screens/home_screen.dart';
import 'package:safety_app/screens/emergency_contacts_screen.dart';
import 'package:safety_app/screens/safety_tips_screen.dart';
import 'package:safety_app/screens/route_map.dart';
import 'package:safety_app/screens/splash_screen.dart';
import 'package:safety_app/screens/onboarding_screen.dart';
import '../screens/map_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/privacy_settings_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/user_profile.dart';

class AppRoutes {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String userProfile = '/profile';
  static const String emergencyContacts = '/emergency-contacts';
  static const String safetyTips = '/safety-tips';
  static const String routeMap = '/route-map';
  static const String settings = '/settings';
  static const String mapScreen = '/map-screen';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';  

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => SplashScreen(),
      onboarding: (context) => OnboardingScreen(),
      emergencyContacts: (context) => EmergencyContactsScreen(),
      safetyTips: (context) => SafetyTipsScreen(),
      routeMap: (context) => MapRouteScreen(),
      userProfile: (context) => UserProfile(),
      settings: (context) => SettingsScreen(),
      notificationSettings: (context) => NotificationSettingsScreen(),
      privacySettings: (context) => PrivacySettingsScreen(),
      mapScreen: (context) => MapScreen(),
    };
  }
}
