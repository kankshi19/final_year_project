import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/screens/Parent/link_child_screen.dart';

class SetupParentPage extends StatefulWidget {
  @override
  _SetupParentPageState createState() => _SetupParentPageState();
}

class _SetupParentPageState extends State<SetupParentPage> {
  final TextEditingController _phoneController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Enter your phone number", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone, color: Colors.blue),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator() // Show loader when saving data
                : ElevatedButton(
                    onPressed: _savePhoneNumber,
                    child: Text("Save & Continue"),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoneNumber() async {
    final String phoneNumber = _phoneController.text.trim();

    // Check if user is logged in
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in. Please sign in again.")),
      );
      return;
    }

    // Validate phone number
    if (phoneNumber.isEmpty || phoneNumber.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid 10-digit phone number.")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loader while saving
    });

    try {
      await FirebaseFirestore.instance.collection('parents').doc(_user!.uid).update({
        'phoneNumber': phoneNumber,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone number saved successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LinkChildScreen()),
      );
    } catch (e) {
      print("Error updating Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save phone number. Try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }
}
