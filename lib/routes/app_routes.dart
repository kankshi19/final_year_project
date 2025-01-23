import 'package:flutter/material.dart';
import 'package:safety_app/screens/safe-route/route_map.dart';
import 'package:safety_app/screens/settings/safety_tips_screen.dart';
import 'package:safety_app/screens/initial/splash_screen.dart';
import 'package:safety_app/screens/initial/onboarding_screen.dart';
import '../screens/community_chat/community_chat_screen.dart';
import '../screens/home/map_screen.dart';
import '../screens/initial/login_screen.dart';
import '../screens/initial/signup_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/user_profile.dart';
import '../screens/emergency/emergency_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String userProfile = '/profile';
  static const String emergencyContacts = '/emergency-contacts';
  static const String safetyTips = '/safety-guidlines';
  static const String routeMap = '/route-map';
  static const String settings = '/settings';
  static const String mapScreen = '/map-screen';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';  
  static const String emergency= '/find-support'; 
  static const String signup= '/signup-screen'; 
  static const String login= '/login-screen';
  static const String community= '/community-screen';

  static Map<String, WidgetBuilder> get routes {
    return {
      signup: (context) => SignupScreen(),
      login: (context) =>  LoginScreen(),
      home: (context) => SplashScreen(),
      onboarding: (context) => OnboardingScreen(),
      safetyTips: (context) => SafetyGuidelinesPage(),
      routeMap: (context) => MapRouteScreen(),
      userProfile: (context) => UserProfile(),
      settings: (context) => SettingsScreen(),
      notificationSettings: (context) => NotificationSettingsScreen(),
      privacySettings: (context) => PrivacySettingsScreen(),
      mapScreen: (context) => MapScreen(),
      emergency: (context) => EmergencyScreen(),
      community:  (context) => CommunityChatScreen(),
    };
  }
}
