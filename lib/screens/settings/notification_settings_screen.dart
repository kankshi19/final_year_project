import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final Color primaryColor = const Color.fromARGB(255, 62, 170, 165);

  bool generalNotifications = true;
  bool emergencyAlerts = true;
  bool safetyTips = true;
  bool locationAlerts = true;
  bool systemPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _checkSystemPermissions();
    await _loadPreferences();
    await _handleNotificationScheduling();
  }

  Future<void> _checkSystemPermissions() async {
    final status = await Permission.notification.status;
    setState(() {
      systemPermissionGranted = status.isGranted;
      if (!systemPermissionGranted) {
        generalNotifications = false;
        emergencyAlerts = false;
        safetyTips = false;
        locationAlerts = false;
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      generalNotifications = prefs.getBool('general_notifications') ?? true;
      emergencyAlerts = prefs.getBool('emergency_alerts') ?? true;
      safetyTips = prefs.getBool('safety_tips') ?? true;
      locationAlerts = prefs.getBool('location_alerts') ?? true;
    });
  }

  Future<void> _handleNotificationScheduling() async {
    if (safetyTips && systemPermissionGranted) {
      await Workmanager().registerPeriodicTask(
        "safety-tips-task",
        "showSafetyTipTask",
        frequency: Duration(minutes: 30),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } else {
      await Workmanager().cancelByUniqueName("safety-tips-task");
    }

    if (!generalNotifications) {
      await NotificationService.cancelAllNotifications();
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    if (!systemPermissionGranted) {
      final permissionResult = await Permission.notification.request();
      setState(() {
        systemPermissionGranted = permissionResult.isGranted;
      });
      if (!systemPermissionGranted) {
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    setState(() {
      switch (key) {
        case 'general_notifications':
          generalNotifications = value;
          break;
        case 'emergency_alerts':
          emergencyAlerts = value;
          break;
        case 'safety_tips':
          safetyTips = value;
          break;
        case 'location_alerts':
          locationAlerts = value;
          break;
      }
    });

    await _handleNotificationScheduling();
  }

  Future<void> _requestSystemPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      systemPermissionGranted = status.isGranted;
    });
    if (systemPermissionGranted) {
      await _loadPreferences();
      await _handleNotificationScheduling();
    }
  }

  Future<void> _sendTestNotification() async {
    if (!systemPermissionGranted) {
      await _requestSystemPermission();
      return;
    }

    await NotificationService.showNotification(
      id: 0,
      title: 'Test Notification',
      body: 'This is a test notification to verify your settings.',
      importance: Importance.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add),
            onPressed: _sendTestNotification,
            tooltip: "Test Notification",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!systemPermissionGranted)
              Container(
                color: Colors.red[100],
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications Disabled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _requestSystemPermission,
                            child: const Text('Enable Notifications'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationCard(
                    icon: Icons.notifications,
                    title: "General Notifications",
                    subtitle: "Updates and general information",
                    value: generalNotifications,
                    onChanged: (value) => _savePreference('general_notifications', value), 
                    systemPermissionGranted: systemPermissionGranted,
                  ),
                  _buildNotificationCard(
                    icon: Icons.warning_rounded,
                    title: "Emergency Alerts",
                    subtitle: "Critical safety notifications",
                    value: emergencyAlerts,
                    isEmergency: true,
                    onChanged: (value) => _savePreference('emergency_alerts', value),
                    systemPermissionGranted: systemPermissionGranted
                  ),
                  _buildNotificationCard(
                    icon: Icons.tips_and_updates,
                    title: "Safety Tips",
                    subtitle: "Receive daily safety reminders",
                    value: safetyTips,
                    onChanged: (value) => _savePreference('safety_tips', value),
                    systemPermissionGranted: systemPermissionGranted
                  ),
                  _buildNotificationCard(
                    icon: Icons.location_on,
                    title: "Location Alerts",
                    subtitle: "Notifications based on your location",
                    value: locationAlerts,
                    onChanged: (value) => _savePreference('location_alerts', value),
                    systemPermissionGranted: systemPermissionGranted
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isEmergency = false,
    required bool systemPermissionGranted,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Icon(
          icon,
          color: isEmergency ? Colors.red : primaryColor,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: systemPermissionGranted ? onChanged : null,
          activeColor: primaryColor,
          activeTrackColor: primaryColor.withOpacity(0.3),
        ),
      ),
    );
  }
