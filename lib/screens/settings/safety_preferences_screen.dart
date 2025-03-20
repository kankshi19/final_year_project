import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants.dart';

class SafetyPreferencesScreen extends StatefulWidget {
  @override
  _SafetyPreferencesScreenState createState() => _SafetyPreferencesScreenState();
}

class _SafetyPreferencesScreenState extends State<SafetyPreferencesScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool autoAlertEnabled = false;
  int alertDelay = 30; // Default delay in seconds
  bool shareLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSafetyPreferences();
  }

  Future<void> _loadSafetyPreferences() async {
    try {
      if (currentUser != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            autoAlertEnabled = userData['autoAlertEnabled'] ?? false;
            alertDelay = userData['alertDelay'] ?? 30;
            shareLocationEnabled = userData['shareLocationEnabled'] ?? false;
          });
        }
      }
    } catch (e) {
      print("Error fetching safety preferences: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateSafetyPreference(String key, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .update({key: value});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Preference updated successfully")),
      );
    } catch (e) {
      print("Error updating safety preference: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update preference")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Preferences"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Customize your safety settings",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: SwitchListTile(
                        title: Text("Auto Alert"),
                        subtitle:
                            Text("Automatically send alert if no response"),
                        value: autoAlertEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            autoAlertEnabled = value;
                          });
                          _updateSafetyPreference('autoAlertEnabled', value);
                        },
                        activeColor:
                            primaryColor,
                        secondary:
                            Icon(Icons.alarm_add, color: Colors.black54),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        title: Text("Alert Delay"),
                        subtitle:
                            Text("Time before auto alert is sent"),
                        trailing: DropdownButton<int>(
                          value: alertDelay,
                          items: [15, 30, 45, 60].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text("$value seconds"),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                alertDelay = newValue;
                              });
                              _updateSafetyPreference('alertDelay', newValue);
                            }
                          },
                          underline:
                              Container(height: 2, color: Colors.transparent),
                          style:
                              TextStyle(color: Colors.black87),
                        ),
                        
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: SwitchListTile(
                        title:
                            Text("Share Location"),
                        subtitle:
                            Text("Share your location with emergency contacts"),
                        value: shareLocationEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            shareLocationEnabled = value;
                          });
                          _updateSafetyPreference('shareLocationEnabled', value);
                        },
                        activeColor:
                            primaryColor,
                        secondary:
                            Icon(Icons.location_on, color: Colors.black54),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Implement test alert functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content:
                              Text("Test alert sent!")),
                        );
                      },
                      iconAlignment: IconAlignment.end,
                      child:
                          Text("Send Test Alert"),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
