import 'package:flutter/material.dart';
import 'package:safety_app/screens/chat-bot/chatbot_screen.dart';
import 'package:safety_app/screens/safe-route/route_map.dart';
import 'package:safety_app/screens/settings/safety_tips_screen.dart';
import 'package:safety_app/screens/initial(User)/splash_screen.dart';
import 'package:safety_app/screens/initial(User)/onboarding_screen.dart';
import '../screens/community_chat/community_chat_screen.dart';
import '../screens/home/map_screen.dart';
import '../screens/initial(User)/login_screen.dart';
import '../screens/initial(User)/signup_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/user_profile.dart';
import '../screens/emergency/emergency_screen.dart';
import '../screens/initial(User)/user_type_selection_screen.dart';
import '../screens/Parent/parent_signup_screen.dart';
import '../screens/Parent/parent_login_screen.dart';
import '../screens/Parent/parent_home_screen.dart';
import '../screens/initial(User)/setup_user.dart';
import '../screens/Parent/setup_parent.dart';
import '../screens/Parent/link_child_screen.dart';
import '../screens/Parent/child_chat_screen.dart';
import '../screens/home/parent_chat_screen.dart';
import '../screens/Parent/parent_profile.dart';

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
  static const String chatbot = '/chat-bot';
  static const String selection = '/selection-screen';
  static const String parentSignup = '/parentSignup-screen';
  static const String parentLogin = '/parentLogin-screen';
  static const String parentHome = '/parentHome-screen';
  static const String setupUser = '/setupUser-screen';
  static const String setupParent = '/setupParent-screen';
  static const String linkChild = '/linkChild-screen';
  static const String childChat = '/childChat-screen';
  static const String parentChat = '/parentChat-screen';
  static const String parentProfile = '/parent-profile';
  


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
      chatbot: (context) => ChatbotScreen(),
      selection: (context) => UserTypeSelectionScreen(),
      parentSignup: (context) => ParentSignupScreen(),
      parentLogin: (context) => ParentLoginScreen(),
      parentHome: (context) => ParentHomeScreen(childId: '',),
      setupUser: (context) => CompleteSetupPage(),
      setupParent: (context) => SetupParentPage(),
      linkChild: (context) => LinkChildScreen(),
      childChat: (context) => ChildChatScreen(childId: 'childId'),
      parentChat: (context) => ParentChatScreen(),
      parentProfile: (context) => ParentProfileScreen()
    };
  }
}
