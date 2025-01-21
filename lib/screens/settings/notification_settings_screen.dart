import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool generalNotifications = true;
  bool emergencyAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      generalNotifications = prefs.getBool('generalNotifications') ?? true;
      emergencyAlerts = prefs.getBool('emergencyAlerts') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {}); // Ensure UI updates after saving
  }

  Future<void> _refreshSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      generalNotifications = prefs.getBool('generalNotifications') ?? true;
      emergencyAlerts = prefs.getBool('emergencyAlerts') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
        backgroundColor: const Color.fromARGB(255, 58, 156, 183),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSettings, // Refresh the settings manually
            tooltip: "Refresh",
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("General Notifications"),
            subtitle: const Text("Enable or disable general notifications"),
            value: generalNotifications,
            onChanged: (bool value) {
              setState(() {
                generalNotifications = value;
                _savePreference('generalNotifications', value);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Emergency Alerts"),
            subtitle: const Text("Receive critical safety alerts"),
            value: emergencyAlerts,
            onChanged: (bool value) {
              setState(() {
                emergencyAlerts = value;
                _savePreference('emergencyAlerts', value);
              });
            },
          ),
        ],
      ),
    );
  }
}
