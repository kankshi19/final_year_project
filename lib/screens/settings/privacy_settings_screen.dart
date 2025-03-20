import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants.dart';


class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool locationTracking = true;
  bool emergencyContacts = true;
  bool hidePersonalInfo = true;
  bool isLocationEnabled = false;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _checkLocationStatus();
  }

  Future<void> _loadUserSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email;
        });

        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            locationTracking = data['locationTracking'] ?? true;
            emergencyContacts = data['emergencyContacts'] ?? true;
            hidePersonalInfo = data['hidePersonalInfo'] ?? true;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error loading settings', Icons.error);
    }
  }

  Future<void> _saveSettings(String setting, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('privacy')
            .set({
          setting: value,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      _showSnackBar('Error saving settings', Icons.error);
    }
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
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        setState(() {
          isLocationEnabled = true;
        });
        _showSnackBar('Location permission granted', Icons.check_circle);
      } else {
        setState(() {
          isLocationEnabled = false;
        });
        _showSnackBar('Location permission denied', Icons.error);
      }
    }
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Settings"),
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
          children: [
            const SizedBox(height: 20),
            _buildSettingTile(
              title: "Location Tracking",
              subtitle: "Allow app to track your location for emergency services",
              icon: Icons.location_on,
              value: locationTracking,
              onChanged: (value) async {
                if (value) {
                  await _requestLocationPermission();
                  if (isLocationEnabled) {
                    setState(() {
                      locationTracking = true;
                    });
                    await _saveSettings('locationTracking', true);
                  }
                } else {
                  setState(() {
                    locationTracking = false;
                  });
                  await _saveSettings('locationTracking', false);
                }
              },
            ),
            _buildSettingTile(
              title: "Emergency Contacts",
              subtitle: "Allow emergency contacts to view your location during alerts",
              icon: Icons.contact_phone,
              value: emergencyContacts,
              onChanged: (value) async {
                setState(() {
                  emergencyContacts = value;
                });
                await _saveSettings('emergencyContacts', value);
              },
            ),
            _buildSettingTile(
              title: "Hide Personal Information",
              subtitle: "Keep your personal details private from other users",
              icon: Icons.visibility_off,
              value: hidePersonalInfo,
              onChanged: (value) async {
                setState(() {
                  hidePersonalInfo = value;
                });
                await _saveSettings('hidePersonalInfo', value);
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'We take your privacy seriously. Your location data is only shared with emergency contacts during active alerts. Personal information is stored securely and never shared without your consent.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.privacy_tip),
                    SizedBox(width: 8),
                    Text('View Privacy Policy'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}