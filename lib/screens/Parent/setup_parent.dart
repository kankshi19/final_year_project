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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complete Setup",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Enter your phone number to get started",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: Color(0xFF2196F3)),
                      prefixIcon: Icon(Icons.phone, color: Color(0xFF2196F3)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savePhoneNumber,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              "Save & Continue",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Color(0xFF2196F3), backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePhoneNumber() async {
    final String phoneNumber = _phoneController.text.trim();

    if (_user == null) {
      _showSnackBar("User not logged in. Please sign in again.");
      return;
    }

    if (phoneNumber.isEmpty || phoneNumber.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      _showSnackBar("Please enter a valid 10-digit phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('parents').doc(_user!.uid).update({
        'phoneNumber': phoneNumber,
      });

      _showSnackBar("Phone number saved successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LinkChildScreen()),
      );
    } catch (e) {
      print("Error updating Firestore: $e");
      _showSnackBar("Failed to save phone number. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

