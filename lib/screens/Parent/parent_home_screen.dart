import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:safety_app/screens/Parent/parent_settings.dart';
import 'child_chat_screen.dart';
import 'parent_profile.dart';
import 'package:safety_app/utils/shared_prefs_helper.dart';
import 'package:intl/intl.dart';


class ParentHomeScreen extends StatefulWidget {
  final String childId;
  final String childName;

  ParentHomeScreen({Key? key, required this.childId, required this.childName}) : super(key: key);

  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  LatLng? _childLocation;
  late MapController _mapController;
  DateTime? lastUpdated;
  bool _isLoading = true;
  double _currentZoom = 15.0;
  String _childName = '';
  String _childAddress = '';
  int _selectedIndex = 0;
  String? selectedChildId;
  String? selectedChildName;

  final Color primaryColor = Color(0xFF3EAAA5);
  final Color secondaryColor = Color(0xFFBC4781);
  final Color chatButtonColor = Color(0xFFFFA500);
  final Color lastUpdatedBgColor = Color(0xFF3EAAA5);
  final Color lastUpdatedTextColor = Colors.white;


  @override
  void initState() {
    super.initState();
    _mapController = MapController();
     _loadSelectedChild();
    // _listenToChildLocation(widget.childId);
    //_fetchChildName(widget.childId);
  }

  Future<void> _loadSelectedChild() async {
    final childId = await SharedPrefsHelper.getSelectedChildId();
    final childName = await SharedPrefsHelper.getSelectedChildName();
    print("DEBUG: Loaded Child -> ID: $childId, Name: $childName");

    if (childId != null && childName != null) {
      setState(() {
        selectedChildId = childId;
        selectedChildName = childName;
      });
      print("DEBUG: Updated UI -> Child ID: $selectedChildId, Name: $selectedChildName");

      _listenToChildLocation(selectedChildId!); // Start listening to location
      //_fetchChildName(selectedChildId!); // Uncomment if needed
    } else {
      print("ERROR: No child found in SharedPreferences. Using widget values.");

      if (widget.childId != null && widget.childId!.isNotEmpty) {
        setState(() {
          selectedChildId = widget.childId;
          selectedChildName = widget.childName.isNotEmpty ? widget.childName : "Unknown Child";
        });

        _listenToChildLocation(selectedChildId!);
        _fetchChildName(selectedChildId!);

        await SharedPrefsHelper.saveSelectedChild(selectedChildId!, selectedChildName!);
        print("DEBUG: Saved Child -> ID: $selectedChildId, Name: $selectedChildName");
      } else {
        print("ERROR: Even widget values are null! Cannot proceed.");
      }
    }
  }

  void _listenToChildLocation(String childId) {
    _dbRef.child('users').child(childId).child('location').onValue.listen((event) {
      setState(() {
        _isLoading = false;
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;

          // Debugging: Print the raw timestamp
          print("Raw Timestamp from Firebase: ${data['timestamp']}");

          final latitude = data['latitude'] as double;
          final longitude = data['longitude'] as double;
          _childLocation = LatLng(latitude, longitude);

          // Convert timestamp safely
          if (data['timestamp'] != null) {
            int timestamp = (data['timestamp'] as num).toInt();
            lastUpdated = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
          } else {
            lastUpdated = null;
          }

          _getAddressFromCoordinates(latitude, longitude);
        } else {
          _childLocation = null;
          lastUpdated = null;
        }
      });
    });
  }


  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _childAddress = "${place.street}, ${place.locality}, ${place.country}";
        });
      } else {
        setState(() {
          _childAddress = "Address not found";
        });
      }
    } catch (e) {
      setState(() {
        _childAddress = "Error fetching address";
      });
    }
  }

  void _fetchChildName(String childId) {
    _dbRef.child('users').child(childId).child('name').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        String? childName = event.snapshot.value?.toString();
        print("DEBUG: Fetched Child Name from Firebase -> $childName");

        if (childName != null && childName.isNotEmpty) {
          setState(() {
            _childName = childName.split(' ')[0]; // Get first name
          });
        } else {
          print("ERROR: Name field is empty for childId: $childId");
        }
      } else {
        print("ERROR: No name found in Firebase for childId: $childId");
      }
    }).catchError((error) {
      print("ERROR: Failed to fetch child name -> $error");
    });
  }


  void _openParentProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentProfileScreen()),
    );
  }

  void _openChatWithChild() {
    if (selectedChildId == null || selectedChildName == null) {
      print("ERROR: Child ID or Name is null when opening chat!");
      return; // Prevent navigation if data is missing
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildChatScreen(childId: selectedChildId!, childName: selectedChildName!, parentId: '',),
      ),
    );
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(1.0, 18.0);
    _mapController.move(_childLocation!, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(1.0, 18.0);
    _mapController.move(_childLocation!, _currentZoom);
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        // Already on home screen, no action needed
        break;
      case 1: // Chat
        _openChatWithChild();
        break;
      case 2: // Settings
        _openSettings();
        break;
    }
  }

  void _openSettings() {
    //You can create and navigate to your settings screen here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentSettingsScreen()),
    );
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading
        ? Center(child: CircularProgressIndicator(color: secondaryColor))
        : Stack(
            children: [
              _buildMap(),
              _buildHeader(),
              _buildZoomControls(),
              _buildLocationCard(),
            ],
          ),
    bottomNavigationBar: _buildBottomNavBar(),
  );
}

Widget _buildMap() {
  return _childLocation != null
      ? FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _childLocation!,
            initialZoom: _currentZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _childLocation!,
                  width: 50.0,
                  height: 50.0,
                  child: Icon(Icons.location_on, color: Colors.red, size: 50),
                ),
              ],
            ),
          ],
        )
      : Center(
          child: Text(
            "No location data available",
            style: GoogleFonts.inter(
              fontSize: 18,
              color: primaryColor,
            ),
          ),
        );
}

Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, secondaryColor],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${selectedChildName!.contains(' ') ? selectedChildName?.split(' ')[0] : selectedChildName}'s Location",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Keep track of your child",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

              ],
            ),
            Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _openParentProfile,
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildLocationCard() {
  return Positioned(
    left: 16,
    right: 16,
    bottom: 10, // Increased bottom padding to accommodate navigation bar
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.navigation, color: primaryColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location: ',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _childAddress,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    lastUpdated != null
                        ? 'Updated at ${DateFormat('dd-MM-yy HH:mm:ss').format(lastUpdated!.toLocal())}'
                        : 'Not Available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusChip('Active', Colors.green),
                  SizedBox(width: 8),
                  _buildStatusChip('GPS Signal: Strong', Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildZoomControls() {
  return Positioned(
    right: 16,
    bottom: 200,
    child: Column(
      children: [
        _buildZoomButton(Icons.add, _zoomIn),
        SizedBox(height: 8),
        _buildZoomButton(Icons.remove, _zoomOut),
      ],
    ),
  );
}

Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
  return Material(
    color: Colors.white,
    elevation: 4,
    borderRadius: BorderRadius.circular(30),
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
        ),
        child: Icon(
          icon,
          color: primaryColor,
          size: 24,
        ),
      ),
    ),
  );
}

Widget _buildStatusChip(String label, Color color) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _buildBottomNavBar() {
  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, -5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
            activeIcon: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home_rounded),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
            activeIcon: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chat_bubble_outline),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
            activeIcon: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings_outlined),
            ),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
        ),
      ),
    ),
  );
}
}