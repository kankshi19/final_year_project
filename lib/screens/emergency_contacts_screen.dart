import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
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
    if (!permission.isGranted) {
      Fluttertoast.showToast(msg: "Contacts permission is required.");
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
  // Request permission
  await _requestContactsPermission();

  try {
    // Open the contact picker
    final Contact? newContact = await _contactPicker.selectContact();

    // Debug the raw contact data
    print("Selected contact: $newContact");

    // Validate the selected contact
    if (newContact != null && newContact.selectedPhoneNumber != null) {
      String name = newContact.fullName?.trim() ?? "Unknown";
      String number = newContact.selectedPhoneNumber?.trim() ?? "";

      if (number.isEmpty) {
        Fluttertoast.showToast(msg: "Selected contact has no phone number.");
        return;
      }

      // Add to the list and save
      setState(() {
        _emergencyContacts.add({'name': name, 'number': number});
      });
      await _saveContacts();

      Fluttertoast.showToast(msg: "$name added successfully.");
    } else {
      Fluttertoast.showToast(msg: "No contact selected or invalid contact.");
    }
  } catch (e) {
    // Handle any errors during the contact picking process
    print("Error picking contact: $e");
    Fluttertoast.showToast(msg: "Failed to pick contact: $e");
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

  // Open the phone dialer
  void _makePhoneCall(String phoneNumber) async {
    final Uri dialUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(dialUri)) {
      await launchUrl(dialUri);
    } else {
      Fluttertoast.showToast(msg: "Could not launch dialer.");
    }
  }

  // Send SOS SMS with current location
  Future<void> _sendSOSAlert() async {
    if (_emergencyContacts.isEmpty) {
      Fluttertoast.showToast(msg: "No emergency contacts to alert.");
      return;
    }

    bool locationPermission = await _requestLocationPermission();
    if (!locationPermission) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String message =
        "Emergency! I need help. My current location is: https://www.google.com/maps?q=${position.latitude},${position.longitude}";

    for (var contact in _emergencyContacts) {
      String phoneNumber = contact['number'] ?? "";
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        Fluttertoast.showToast(
            msg: "Failed to send SMS to ${contact['name']}");
      }
    }
  }

  // Request location permission
  Future<bool> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();
    if (!permission.isGranted) {
      Fluttertoast.showToast(msg: "Location permission is required.");
      return false;
    }
    return true;
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
      floatingActionButton: FloatingActionButton(
        onPressed: _sendSOSAlert,
        backgroundColor: Colors.red,
        child: Text(
          "SOS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
