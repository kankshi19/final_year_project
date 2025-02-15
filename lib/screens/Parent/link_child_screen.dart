import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/screens/Parent/parent_home_screen.dart';
import 'package:lottie/lottie.dart';

class LinkChildScreen extends StatefulWidget {
  @override
  _LinkChildScreenState createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childPhoneController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _linkedChildren = [];

  @override
  void initState() {
    super.initState();
    _fetchLinkedChildren();
  }

  Future<void> _fetchLinkedChildren() async {
    String parentId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('parent_child_links')
        .where('parentId', isEqualTo: parentId)
        .get();

    List<Map<String, dynamic>> tempList = [];

    for (var doc in querySnapshot.docs) {
      String childId = doc['childId'];
      String childPhone = doc['childPhone'];

      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .get();

      String childName = 'Unknown';

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData =
            childSnapshot.data() as Map<String, dynamic>?;

        if (childData != null && childData.containsKey('name')) {
          childName = childData['name'];
        }
      }

      tempList.add({
        'childId': childId,
        'childName': childName,
        'childPhone': childPhone,
        'status': doc['status'],
      });
    }

    // Update state with fetched children
    setState(() {
      _linkedChildren = tempList;
    });
  }

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

        _childPhoneController.clear();
        await _fetchLinkedChildren(); // Refresh list
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Link Your Child',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_UW8DlCRljO.json',
                  height: 200,
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _childPhoneController,
                        decoration: InputDecoration(
                          labelText: "Child's Phone Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.phone, color: Color(0xFF00838F)),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty ? 'Enter a phone number' : null,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _linkChild,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Link Child', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00838F),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Linked Children',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: _linkedChildren.isEmpty
                      ? Center(
                          child: Text(
                            'No children linked yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _linkedChildren.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFF00838F),
                                  child: Text(
                                    _linkedChildren[index]['childName'][0].toUpperCase(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  _linkedChildren[index]['childName'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Phone: ${_linkedChildren[index]['childPhone']}'),
                                trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF00838F)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ParentHomeScreen(
                                          childId: _linkedChildren[index]['childId']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
