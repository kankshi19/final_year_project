import 'package:flutter/material.dart';
import 'package:safety_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_app/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/theme_provider.dart';

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

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
    _saveTheme(value);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  Future<void> _resetAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("App data has been reset.")),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FadeInUp(
              child: _buildSettingsSection(
                title: 'Preferences',
                children: [
                  _buildSettingsTile(
                    icon: Icons.color_lens,
                    title: 'Theme',
                    subtitle: 'Switch between light and dark mode',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: _toggleTheme,
                      activeColor: primaryColor,
                    ),
                    onTap: () => _toggleTheme(!isDarkMode),
                  ),
                ],
              ),
            ),
            
            FadeInUp(
              delay: Duration(milliseconds: 200),
              child: _buildSettingsSection(
                title: 'Account',
                children: [
                  _buildSettingsTile(
                    icon: Icons.account_circle,
                    title: 'Account Settings',
                    subtitle: 'Manage your account details',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.userProfile),
                  ),
                  _buildSettingsTile(
                    icon: Icons.logout,
                    title: 'Log Out',
                    subtitle: 'Securely exit your account',
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            
            FadeInUp(
              delay: Duration(milliseconds: 400),
              child: _buildSettingsSection(
                title: 'App Management',
                children: [
                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.notificationSettings),
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy',
                    subtitle: 'Manage your privacy settings',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
                  ),
                  _buildSettingsTile(
                    icon: Icons.check_circle_outline,
                    title: 'Check-in',
                    subtitle: 'Manage your auto-checkins',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.checkin),
                  ),
                  _buildSettingsTile(
                    icon: Icons.refresh,
                    title: 'Reset App',
                    subtitle: 'Clear all app data and settings',
                    onTap: () => _showResetDialog(context),
                  ),
                ],
              ),
            ),
            
            FadeInUp(
              delay: Duration(milliseconds: 600),
              child: _buildSettingsSection(
                title: 'Additional Resources',
                children: [
                  _buildSettingsTile(
                    icon: Icons.favorite,
                    title: 'Safety Guidelines',
                    subtitle: 'Stay safe and secure',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.safetyTips),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text("Reset App"),
        content: Text(
          "Are you sure you want to reset all app data? This action cannot be undone.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel", style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAppData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text("Log Out"),
        content: Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel", style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, AppRoutes.selection);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Log Out"),
          ),
        ],
      ),
    );
  }
}