import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ParentProfileScreen extends StatefulWidget {
  @override
  _ParentProfileScreenState createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimedb = FirebaseDatabase.instance;

  // App color scheme - using teal variations
  final Color primaryTeal = const Color(0xFF3EAAA5);
  final Color lightTeal = const Color(0xFFE0F4F3);
  final Color brighterTeal = const Color(0xFF65C8C4); // Brighter version
  final Color accentYellow = const Color(0xFFFFC107);

  String parentName = "";
  String parentPhone = "";
  String parentEmail = "";
  List<Map<String, dynamic>> children = [];
  Map<String, String> childAddresses = {};

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
          parentEmail = parentSnapshot["email"] ?? "N/A";
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
            "id": childId,
            "name": childSnapshot["name"] ?? "Unknown",
          });

          // Fetch and update child address
          fetchChildAddress(childId).then((address) {
            setState(() {
              childAddresses[childId] = address ?? "Address not available";
            });
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

  Future<String?> fetchChildAddress(String childId) async {
  try {
    DatabaseReference ref = _realtimedb.ref("users/$childId/location");
    DatabaseEvent event = await ref.once();

    if (event.snapshot.value == null) {
      print("⚠️ Location not available for $childId");
      return "Location not available";
    }

    // Map location data
    Map<String, dynamic> locationData =
        Map<String, dynamic>.from(event.snapshot.value as Map);

    // Extract latitude and longitude
    double latitude = locationData["latitude"];
    double longitude = locationData["longitude"];

    print("📍 Latitude: $latitude, Longitude: $longitude");

    // Perform reverse geocoding
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      print("✅ Address: ${place.street}, ${place.locality}");
      return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } else {
      print("❓ Address not found for $childId");
      return "Address not found";
    }
  } catch (e) {
    print("❌ Error: $e");
    return "Error fetching address";
  }
}

     @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Top decorative wave - Using lighter teal gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    brighterTeal,
                    primaryTeal,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildTopSection(),
                        SizedBox(height: 30),
                        _buildStatsSection(),
                        SizedBox(height: 30),
                        _buildChildrenSection(),
                        SizedBox(height: 30),
                        _buildLogoutButton(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: brighterTeal, // Lighter teal
            ),
          ).animate().scale().fade(),
          SizedBox(height: 20),
          Text(
            parentName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactInfo(
            icon: Icons.email,
            title: "Email",
            value: parentEmail,
            color: primaryTeal,
          ),
          Divider(height: 30),
          _buildContactInfo(
            icon: Icons.phone,
            title: "Phone",
            value: parentPhone,
            color: accentYellow,
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0);
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            "Children",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        SizedBox(height: 20),
        if (children.isEmpty)
          Center(
            child: Text(
              "No linked children found.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              final childId = child["id"];
              return Container(
                margin: EdgeInsets.only(bottom: 15),
                child: Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 25),
                          Text(
                            child["name"],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: brighterTeal, // Lighter teal
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  childAddresses[childId] ?? "Updating location...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 20,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              brighterTeal, // Lighter teal
                              primaryTeal,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: brighterTeal.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.child,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(delay: (500 + 100 * index).ms)
                .slideX(begin: 0.2, end: 0);
            },
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout),
        label: Text(
          "Logout",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: brighterTeal, // Lighter teal for button
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          await _auth.signOut();
          Navigator.pop(context);
        },
      ),
    ).animate().fadeIn(delay: 800.ms).scale();
  }
}