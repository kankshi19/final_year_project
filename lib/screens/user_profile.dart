import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:safety_app/screens/emergency_screen.dart';
import '../routes/app_routes.dart';
import 'safety_preferences_screen.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String? displayName;
  String? email;
  String? profilePicUrl;
  List<Map<String, String>> emergencyContacts = [];
  // List<Contact?> emergencyContacts = [];
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
        await _loadEmergencyContacts();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadEmergencyContacts() async {
  try {
    var contactsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .collection('emergency_contacts')
        .get();

    setState(() {
      emergencyContacts = contactsSnapshot.docs.map((doc) {
        return {
          'name': doc['name']?.toString() ?? 'Unknown',
          'phone': doc['phone']?.toString() ?? 'No phone number',
        };
      }).toList();
    });
  } catch (e) {
    print("Error loading emergency contacts: $e");
  }
}


  Future<void> _addEmergencyContact() async {
    try {
      final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
      final Contact? contact = await contactPicker.selectContact();

      if (contact != null && contact.phoneNumbers!.isNotEmpty) {
        String phone = contact.phoneNumbers!.first.trim() ?? 'No phone';
        String name = contact.fullName ?? 'Unknown';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('emergency_contacts')
            .add({
          'name': name,
          'phone': phone,
        });

        await _loadEmergencyContacts();
      }
    } catch (e) {
      print("Error adding emergency contact: $e");
    }
  }

  Future<void> _deleteEmergencyContact(Map<String, String> contact) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('emergency_contacts')
          .where('phone', isEqualTo: contact['phone'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      await _loadEmergencyContacts();
    } catch (e) {
      print("Error deleting emergency contact: $e");
    }
  }

  void _showEmergencyContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Contacts"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...emergencyContacts.map((contact) => ListTile(
                    title: Text(contact['name'] ?? ''),
                    subtitle: Text(contact['phone'] ?? ''),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteEmergencyContact(contact);
                      },
                    ),
                  )),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addEmergencyContact();
                },
                child: Text("Add Contact"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 58, 156, 183),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
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
                      title: const Text("Emergency Contacts"),
                      subtitle: Text("${emergencyContacts.length} contacts"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 58, 156, 183)),
                        onPressed: () => _showEmergencyContactsDialog(context),
                      ),
                    ),
                    const Divider(),
                    // Emergency Screen Navigation
                    ListTile(
                      leading: const Icon(Icons.emergency, color: Color.fromARGB(255, 58, 156, 183)),
                      title: const Text("Emergency & Nearby Support"),
                      subtitle: const Text("Access emergency features"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EmergencyScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    // Safety Preferences Section
                    ListTile(
                      leading: const Icon(Icons.shield, color: Color.fromARGB(255, 58, 156, 183)),
                      title: const Text("Safety Preferences"),
                      subtitle: const Text("Customize your safety settings."),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SafetyPreferencesScreen()),
                        );
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
