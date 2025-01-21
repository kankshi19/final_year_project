import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool locationTracking = true;
  bool dataSharing = false;
  bool isLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkLocationStatus();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      locationTracking = prefs.getBool('locationTracking') ?? true;
      dataSharing = prefs.getBool('dataSharing') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _checkLocationStatus() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      isLocationEnabled = isEnabled;
    });
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      // Request location permission
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        // Location permission granted
        setState(() {
          isLocationEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission granted.")),
        );
      } else {
        // Location permission denied
        setState(() {
          isLocationEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
      }
    } else if (status.isGranted) {
      // Permission already granted
      setState(() {
        isLocationEnabled = true;
      });
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, open app settings
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Settings"),
        backgroundColor: const Color.fromARGB(255, 58, 156, 183),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Location Tracking"),
            subtitle: Text(
              isLocationEnabled
                  ? "Location is enabled on your device"
                  : "Location is disabled on your device",
            ),
            value: locationTracking,
            onChanged: (bool value) async {
              if (value) {
                await _requestLocationPermission();
                if (isLocationEnabled) {
                  setState(() {
                    locationTracking = true;
                    _savePreference('locationTracking', true);
                  });
                }
              } else {
                setState(() {
                  locationTracking = false;
                  _savePreference('locationTracking', false);
                });
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Data Sharing"),
            subtitle: const Text("Allow sharing your data anonymously for research"),
            value: dataSharing,
            onChanged: (bool value) {
              setState(() {
                dataSharing = value;
                _savePreference('dataSharing', value);
              });
            },
          ),
        ],
      ),
    );
  }
}
