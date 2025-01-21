import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_app/routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/bottom_navbar_widget.dart'; // Assuming you use AppRoutes for navigation

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Load theme preference
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Save theme preference
  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  // Toggle theme
  void _toggleTheme(bool value) {
  setState(() {
    isDarkMode = value;
  });
  _saveTheme(value); // Save the new preference
  // Trigger theme change in the app
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  themeProvider.toggleTheme();
}

  Future<void> _resetAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all shared preferences data
    // Add any additional reset logic here if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("App data has been reset.")),
    );
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color.fromARGB(255, 58, 156, 183),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Notification Settings
          ListTile(
            leading: const Icon(Icons.notifications,
                color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Notifications"),
            subtitle: const Text("Manage notification preferences"),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notificationSettings);
            },
          ),
          const Divider(),

          // Privacy Settings
          ListTile(
            leading: const Icon(Icons.privacy_tip,
                color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Privacy"),
            subtitle: const Text("Manage your privacy settings"),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.privacySettings);
            },
          ),
          const Divider(),

          // Theme Settings
          
          ListTile(
            leading: const Icon(Icons.color_lens, color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Theme"),
            subtitle: const Text("Switch between light and dark mode"),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                _toggleTheme(value);
              },
            ),
            onTap: () {
              _toggleTheme(!isDarkMode); // Toggle the theme when the ListTile is tapped
            },
          ),
          const Divider(),

          // Account Settings
          ListTile(
            leading: const Icon(Icons.account_circle,
                color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Account"),
            subtitle: const Text("Manage your account settings"),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.userProfile);
            },
          ),
          const Divider(),

          // Reset App Data
          ListTile(
            leading: const Icon(Icons.refresh,
                color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Reset App"),
            subtitle: const Text("Clear all app data and settings"),
            onTap: () {
              _showResetDialog(context);
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.favorite,
                color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Safety Guidlines"),
            subtitle: const Text("Stay safe and secure"),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.safetyTips);
            },
          ),

          const Divider(),

          // Log Out
          ListTile(
            leading: const Icon(Icons.logout,
                color: Color.fromARGB(255, 58, 156, 183)),
            title: const Text("Log Out"),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset App"),
        content: const Text(
            "Are you sure you want to reset all app data? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAppData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 58, 156, 183),
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
              // Add FirebaseAuth sign-out logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 58, 156, 183),
            ),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );
  }
}
