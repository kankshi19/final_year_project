import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'child_chat_screen.dart';
import 'parent_profile.dart'; // Import the Parent Profile Screen

class ParentHomeScreen extends StatefulWidget {
  final String childId;

  ParentHomeScreen({Key? key, required this.childId}) : super(key: key);

  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  LatLng? _childLocation;
  late MapController _mapController;
  DateTime? lastUpdated;
  bool _isLoading = true; // Loader flag

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _listenToChildLocation(widget.childId);
  }

  // Listen for child location updates in Firebase
  void _listenToChildLocation(String childId) {
    _dbRef.child("users").child(childId).child("location").onValue.listen((event) {
      if (event.snapshot.exists) {
        var data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null && data.containsKey("latitude") && data.containsKey("longitude")) {
          try {
            double lat = double.parse(data["latitude"].toString());
            double lng = double.parse(data["longitude"].toString());
            DateTime updatedTime = DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(data["timestamp"].toString()) ?? DateTime.now().millisecondsSinceEpoch,
            );

            if (_childLocation == null || _childLocation!.latitude != lat || _childLocation!.longitude != lng) {
              setState(() {
                _childLocation = LatLng(lat, lng);
                lastUpdated = updatedTime;
                _isLoading = false; // Hide loader
              });

              _mapController.move(_childLocation!, 15.0); // Move map to new location
            }
          } catch (e) {
            print("Error parsing location: $e");
          }
        }
      }
    });
  }

  // Navigate to Parent Profile Screen
  void _openParentProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentProfileScreen()),
    );
  }

  // Navigate to chat screen with the selected child
  void _openChatWithChild() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildChatScreen(childId: widget.childId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Child's Location"),
        actions: [
          IconButton(
            icon: Icon(Icons.person), // Profile Icon
            onPressed: _openParentProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader until data is available
          : Column(
              children: [
                // Display map with child's location
                if (_childLocation != null)
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _childLocation!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _childLocation!,
                              width: 40.0,
                              height: 40.0,
                              child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Center(child: Text("No location data available")),

                // Display last updated time
                if (lastUpdated != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Last Updated: ${lastUpdated!.toLocal()}'),
                  ),

                // Chat button to communicate with the child
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.chat),
                    label: Text('Chat with Child'),
                    onPressed: _openChatWithChild,
                  ),
                ),
              ],
            ),
    );
  }
}
