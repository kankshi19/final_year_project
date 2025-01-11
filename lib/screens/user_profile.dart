import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../routes/app_routes.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String? displayName;
  String? email;
  String? profilePicUrl;
  String? emergencyContact;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (currentUser != null) {
        displayName = currentUser?.displayName ?? "User";
        email = currentUser?.email ?? "No email";
        profilePicUrl = currentUser?.photoURL ?? "";

        // Fetch additional user data from Firestore
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          emergencyContact = userData['emergencyContact'] ?? "Not set";
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding); // Redirect to onboarding screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: const Color.fromARGB(255, 58, 156, 183),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePicUrl != null && profilePicUrl!.isNotEmpty
                          ? NetworkImage(profilePicUrl!)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    const SizedBox(height: 20),
                    // User Name
                    Text(
                      displayName ?? "User",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Text(
                      email ?? "No email available",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Emergency Contact
                    ListTile(
                      leading: const Icon(Icons.phone, color: Color.fromARGB(255, 58, 156, 183)),
                      title: const Text("Emergency Contact"),
                      subtitle: Text(emergencyContact ?? "Not set"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 58, 156, 183)),
                        onPressed: () {
                          // Add logic to edit emergency contact
                        },
                      ),
                    ),
                    const Divider(),
                    // Safety Preferences Section
                    ListTile(
                      leading: const Icon(Icons.shield, color: Color.fromARGB(255, 58, 156, 183)),
                      title: const Text("Safety Preferences"),
                      subtitle: const Text("Customize your safety settings."),
                      onTap: () {
                        // Navigate to Safety Preferences screen
                      },
                    ),
                    const Divider(),
                    // Device Management Section
                    ListTile(
                      leading: const Icon(Icons.device_hub, color: Color.fromARGB(255, 58, 156, 183)),
                      title: const Text("Device Management"),
                      subtitle: const Text("Manage your wearable device."),
                      onTap: () {
                        // Navigate to Device Management screen
                      },
                    ),
                    const Divider(),
                    // Sign Out Button
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showSignOutDialog(context),
                      icon: const Icon(Icons.logout),
                      label: const Text("Sign Out"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 58, 156, 183),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 58, 156, 183)),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }
}
