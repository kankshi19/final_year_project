import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'child_chat_screen.dart'; // Import the Chat Screen

class ParentHomeScreen extends StatefulWidget {
  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String? childUserId;
  late MapController _mapController;
  LatLng? _childLocation;
  LatLng _defaultCenter = LatLng(20.5937, 78.9629); // Center of India
  List<Marker> _markers = [];
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchLinkedChild();
  }

  Future<void> _fetchLinkedChild() async {
    try {
      String parentId = FirebaseAuth.instance.currentUser!.uid;
      print("Parent ID: $parentId");

      // ✅ Fetch from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('parent_child_links')
          .where('parentId', isEqualTo: parentId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String linkedChildId = querySnapshot.docs.first['childId'];
        print("Found linked child ID: $linkedChildId");

        setState(() {
          childUserId = linkedChildId;
        });

        _listenToChildLocation(linkedChildId);
      } else {
        print("No linked child found!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No linked child found. Please link a child first.")),
        );
      }
    } catch (e) {
      print("Error getting linked child: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Unable to fetch linked child.")),
      );
    }
  }

  void _listenToChildLocation(String childId) {
    print("Listening for child's location updates: $childId");

    _dbRef.child("users").child(childId).child("location").onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null && data.containsKey("latitude") && data.containsKey("longitude")) {
          double lat = double.parse(data["latitude"].toString());
          double lng = double.parse(data["longitude"].toString());

          print("Child location: $lat, $lng");

          setState(() {
            _childLocation = LatLng(lat, lng);
            lastUpdated = DateTime.fromMillisecondsSinceEpoch(
              int.parse(data["timestamp"].toString())
            );
            _markers = [
              Marker(
                point: _childLocation!,
                width: 40.0,
                height: 40.0,
                child: Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ];
          });

          // Move the map to the child's location
          _mapController.move(_childLocation!, 15.0);
        }
      } else {
        print("No location data available.");
      }
    }, onError: (error) {
      print("Error fetching location: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location updates"))
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Child's Location"),
        actions: [
          IconButton(
            icon: Icon(Icons.chat), // ✅ Chat icon added
            onPressed: () {
              if (childUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChildChatScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No linked child to chat with.")),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (childUserId != null) {
                _listenToChildLocation(childUserId!);
              } else {
                _fetchLinkedChild();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _childLocation ?? _defaultCenter,
                initialZoom: 15.0,
                minZoom: 3.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _childLocation != null 
                    ? "Location: ${_childLocation!.latitude}, ${_childLocation!.longitude}"
                    : "Waiting for location updates...",
                ),
                SizedBox(height: 4),
                Text("Last Updated: ${lastUpdated ?? "Not available"}"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
