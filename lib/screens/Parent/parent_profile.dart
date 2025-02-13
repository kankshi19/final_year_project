import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentProfileScreen extends StatefulWidget {
  @override
  _ParentProfileScreenState createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String parentName = "";
  String parentPhone = "";
  List<Map<String, dynamic>> children = [];

  @override
  void initState() {
    super.initState();
    _fetchParentAndChildrenData();
  }

  Future<void> _fetchParentAndChildrenData() async {
    String? parentId = _auth.currentUser?.uid;
    if (parentId == null) return;

    try {
      DocumentSnapshot parentSnapshot =
          await _firestore.collection("parents").doc(parentId).get();
      if (parentSnapshot.exists) {
        setState(() {
          parentName = parentSnapshot["name"] ?? "Unknown";
          parentPhone = parentSnapshot["phoneNumber"] ?? "N/A";
        });
      }

      QuerySnapshot childLinksSnapshot = await _firestore
          .collection("parent_child_links")
          .where("parentId", isEqualTo: parentId)
          .get();

      List<String> childIds =
          childLinksSnapshot.docs.map((doc) => doc["childId"].toString()).toList();

      List<Map<String, dynamic>> fetchedChildren = [];
      for (String childId in childIds) {
        DocumentSnapshot childSnapshot =
            await _firestore.collection("users").doc(childId).get();
        if (childSnapshot.exists) {
          fetchedChildren.add({
            "name": childSnapshot["name"] ?? "Unknown",
            //"phoneNumber": childSnapshot["phoneNumber"] ?? "N/A",
          });
        }
      }

      setState(() {
        children = fetchedChildren;
      });
    } catch (e) {
      print("Error fetching parent or child data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Parent Profile")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, size: 50, color: Colors.blue),
                    ),
                    SizedBox(height: 10),
                    Text(
                      parentName,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Phone: $parentPhone",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Linked Children",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            children.isEmpty
                ? Text("No linked children found.", style: TextStyle(color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.child_care, color: Colors.blue),
                          title: Text(children[index]["name"]),
                          //subtitle: Text("Phone: ${children[index]["phone"]}"),
                        ),
                      );
                    },
                  ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
