import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  @override
  _EmergencyContactsScreenState createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, String>> _emergencyContacts = [];
  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
  }

  // Request contacts permission
  Future<void> _requestContactsPermission() async {
    PermissionStatus permission = await Permission.contacts.request();
    if (permission.isGranted) {
      return;
    } else {
      Fluttertoast.showToast(msg: "Contacts permission is required.");
    }
  }

  // Open the phone dialer
  void _makePhoneCall(String phoneNumber) async {
    final Uri dialUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(dialUri)) {
      await launchUrl(dialUri);
    } else {
      Fluttertoast.showToast(msg: "Could not launch dialer.");
    }
  }

  // Load contacts from SharedPreferences
  Future<void> _loadSavedContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedContacts = prefs.getStringList('emergency_contacts') ?? [];
    setState(() {
      _emergencyContacts = savedContacts
          .map((e) {
            var parts = e.split('::');
            return {'name': parts[0], 'number': parts[1]};
          })
          .toList();
    });
  }

  // Save contacts to SharedPreferences
  Future<void> _saveContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> contactsToSave = _emergencyContacts
        .map((contact) => "${contact['name']}::${contact['number']}")
        .toList();
    await prefs.setStringList('emergency_contacts', contactsToSave);
  }

  // Add a new contact using the native contact picker
  Future<void> _addContact() async {
    await _requestContactsPermission();
    final Contact? newContact = await _contactPicker.selectContact();
    if (newContact != null && newContact.selectedPhoneNumber != null) {
      String name = newContact.fullName ?? "Unknown";
      String number = newContact.selectedPhoneNumber ?? "";
      setState(() {
        _emergencyContacts.add({'name': name, 'number': number});
      });
      Fluttertoast.showToast(msg: "$name added successfully.");
      _saveContacts();
    }
  }

  // Delete a contact
  void _deleteContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    _saveContacts();
    Fluttertoast.showToast(msg: "Contact removed.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Contacts"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addContact,
          )
        ],
      ),
      body: _emergencyContacts.isNotEmpty
          ? ListView.builder(
              itemCount: _emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return ListTile(
                  title: Text(contact['name'] ?? "Unknown"),
                  subtitle: Text(contact['number'] ?? ""),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContact(index),
                  ),
                  onTap: () => _makePhoneCall(contact['number'] ?? ""),
                );
              },
            )
          : Center(
              child: Text("No emergency contacts added yet."),
            ),
    );
  }
}
