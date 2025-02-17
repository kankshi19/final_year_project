import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/home/home_screen.dart';

class CompleteSetupPage extends StatefulWidget {
  @override
  _CompleteSetupPageState createState() => _CompleteSetupPageState();
}

class _CompleteSetupPageState extends State<CompleteSetupPage> {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please enter your phone number",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone, color: Color.fromARGB(255, 31, 166, 187)),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePhoneNumber,
                      child: Text("Save Phone Number"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Function to Save User's Phone Number & Set Role as "User"
  Future<void> _savePhoneNumber() async {
    String phoneNumber = _phoneController.text.trim();

    if (_user == null) {
      _showSnackBar("User not logged in. Please sign in again.");
      return;
    }

    if (phoneNumber.isEmpty || phoneNumber.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      _showSnackBar("Enter a valid 10-digit phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save user details in Firestore and set role as "user"
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'phoneNumber': phoneNumber,
        'role': 'user', // Ensuring this entry is marked as a user
      }, SetOptions(merge: true));

      _showSnackBar("Phone number saved successfully!");

      // Navigate to HomeScreen after saving phone number
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print("Error saving phone number: $e");
      _showSnackBar("Failed to save phone number. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Function to Show SnackBar Message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
