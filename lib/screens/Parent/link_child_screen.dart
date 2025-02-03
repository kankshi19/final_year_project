import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/screens/Parent/parent_home_screen.dart';

class LinkChildScreen extends StatefulWidget {
  @override
  _LinkChildScreenState createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childPhoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _linkChild() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String parentId = FirebaseAuth.instance.currentUser!.uid;

        QuerySnapshot childQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: _childPhoneController.text)
            .get();

        if (childQuery.docs.isEmpty) {
          throw Exception('No user found with this phone number.');
        }

        String childId = childQuery.docs.first.id;

        QuerySnapshot existingLinkQuery = await FirebaseFirestore.instance
            .collection('parent_child_links')
            .where('parentId', isEqualTo: parentId)
            .where('childId', isEqualTo: childId)
            .get();

        if (existingLinkQuery.docs.isNotEmpty) {
          throw Exception('This child is already linked to your account.');
        }

        await FirebaseFirestore.instance.collection('parent_child_links').add({
          'parentId': parentId,
          'childId': childId,
          'childPhone': _childPhoneController.text,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Child linked successfully!')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ParentHomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Link Child')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _childPhoneController,
                decoration: InputDecoration(
                  labelText: "Child's Phone Number",
                  hintText: 'Enter the phone number of your child',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a phone number' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _linkChild,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Link Child'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
