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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            ElevatedButton(
              onPressed: _savePhoneNumber,
              child: Text("Save Phone Number"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoneNumber() async {
    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isNotEmpty && phoneNumber.length == 10) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'phoneNumber': phoneNumber,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        print("Error saving phone number: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save phone number.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter a valid 10-digit phone number.")));
    }
  }
}
