import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';


class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {

  List<Contact?> emergencyContacts = [];
  List<Map<String, dynamic>> nearbyPlaces = [];
  LocationData? _currentLocation;
  final Location location = Location();
  final String googleMapsApiKey = 'AIzaSyBNshGF10FPBnYO4oaYTnN2Lxuu580rxd8';
  late AnimationController _sosAnimationController;
  bool _isLoading = true;

  int _countdown = 10;
  Timer? _timer;

  void _startCountdown(BuildContext context) {
    _countdown = 10;

    // Start the countdown timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _triggerSOS();
        timer.cancel();
      }
    });

    // Show the confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Emergency SOS!"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Sending emergency SOS in $_countdown seconds..."),
                  SizedBox(height: 10),
                  CircularProgressIndicator(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text("I'm OK, Cancel SOS"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerSOS() {
    Navigator.pop(context); // Close the dialog
    sendSOS();
  }

  void sendSOS() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("sos_trigger/$userId");
      ref.set({
        "triggered": true,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      }).then((_) {
        print("✅ SOS Triggered!");
      }).catchError((error) {
        print("❌ Failed to trigger SOS: $error");
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _sosAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _initializeData();
  }

  Future<void> _initializeData() async {
    _getCurrentLocation();
    loadAllEmergencyContacts();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _sosAnimationController.dispose();
    super.dispose();
  }

  
// Function to load emergency contacts when user logs in
void loadAllEmergencyContacts() async {
  try {
    // Load predefined contacts first
    final List<Contact> predefinedContacts = [
      Contact(fullName: 'Police', phoneNumbers: ['100']),
      Contact(fullName: 'Women Helpline', phoneNumbers: ['181']),
      Contact(fullName: 'Ambulance', phoneNumbers: ['102']),
    ];

    // Get current user ID
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    
    // Listen to personal contacts in real-time
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        // Combine predefined contacts with personal contacts
        emergencyContacts = [
          ...predefinedContacts,
          ...snapshot.docs.map((doc) => Contact(
                fullName: doc['name'],
                phoneNumbers: [doc['phone']],
              )).toList(),
        ];
      });
    });
  } catch (e) {
    print('Error loading emergency contacts: $e');
  }
}

  // Get the user's live location
  void _getCurrentLocation() async {
    final LocationData locationData = await location.getLocation();
    setState(() {
      _currentLocation = locationData;
    });
    _fetchNearbyPlaces();
  }

  // Fetch nearby places using Google Maps API
  void _fetchNearbyPlaces() async {
    if (_currentLocation == null) return;
    final double latitude = _currentLocation!.latitude!;
    final double longitude = _currentLocation!.longitude!;
    final Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=1500&type=police|hospital|point_of_interest&key=$googleMapsApiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nearbyPlaces = List<Map<String, dynamic>>.from(
          data['results'].map((place) => {
                'name': place['name'],
                'lat': place['geometry']['location']['lat'],
                'lng': place['geometry']['location']['lng'],
              }),
        );
      });
    }
  }

  // Add a new emergency contact
  void _addEmergencyContact() async {
  final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
  final Contact? contact = await contactPicker.selectContact();
  
  // Get current user ID
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  
  if (contact != null) {
    setState(() {
      emergencyContacts.add(contact);
      
      // Save to Firestore under the user's document
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .add({
        'name': contact.fullName,
        'phone': contact.phoneNumbers?.first,
        'timestamp': FieldValue.serverTimestamp(), 
      });
    });
  }
}

  // Make a call
Future<void> _makeCall(String phoneNumber) async {
  var status = await Permission.phone.status;
  if (status.isDenied) {
    status = await Permission.phone.request();
  }

  if (status.isGranted) {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print('Could not launch $phoneNumber: $e');
      throw 'Could not launch $phoneNumber';
    }
  } else {
    throw 'Phone call permission denied';
  }
}
String? getCurrentUserId() {
  User? user = FirebaseAuth.instance.currentUser;
  return user?.uid; // Returns UID if user is logged in
}


  // Open Google Maps for a nearby place
  void _openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  // Delete an emergency contact
  void _deleteContact(int index) {
    setState(() {
      emergencyContacts.removeAt(index);
      // Optionally remove from Firestore as well
      FirebaseFirestore.instance.collection('emergency_contacts').doc().delete();
    });
  }

   @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    return Material(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSOSButton(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _buildEmergencyServicesSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _buildPersonalContactsSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _buildNearbySupportSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: _sosAnimationController,
      builder: (context, child) {
        return GestureDetector(
          onDoubleTap: () => _startCountdown(context),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF4B4B),
                  Color(0xFFFF6B6B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF4B4B).withOpacity(0.3),
                  blurRadius: 12 + (_sosAnimationController.value * 12),
                  spreadRadius: 2 + (_sosAnimationController.value * 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 40 + (_sosAnimationController.value * 8),
                ),
                SizedBox(height: 8),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Tap to Send Emergency Alert',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyServicesSection() {
    final predefinedContacts = emergencyContacts
        .where((contact) => 
            ['Police', 'Women Helpline', 'Ambulance'].contains(contact?.fullName))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 3, 85, 82).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emergency_share,
                    color: primaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: predefinedContacts.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = predefinedContacts[index];
              return _buildEmergencyContactTile(
                contact: contact!,
                icon: _getEmergencyServiceIcon(contact.fullName ?? ''),
                color: _getEmergencyServiceColor(contact.fullName ?? ''),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalContactsSection() {
    final personalContacts = emergencyContacts
        .where((contact) => 
            !['Police', 'Women Helpline', 'Ambulance'].contains(contact?.fullName))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 3, 85, 82).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people_alt_outlined,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Trusted Contacts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  onPressed: _addEmergencyContact,
                ),
              ],
            ),
          ),
          if (personalContacts.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No trusted contacts added yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to add contacts',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: personalContacts.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final contact = personalContacts[index];
                return Dismissible(
                  key: Key(contact?.fullName ?? ''),
                  background: Container(
                    color: Colors.red.shade100,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    final fullIndex = emergencyContacts.indexOf(contact);
                    _deleteContact(fullIndex);
                  },
                  child: _buildEmergencyContactTile(
                    contact: contact!,
                    icon: Icons.person_outline,
                    color: primaryColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNearbySupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 3, 85, 82).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: primaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Nearby Support Centers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (nearbyPlaces.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No nearby support centers found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: nearbyPlaces.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final place = nearbyPlaces[index];
                return ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    place['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _openGoogleMaps(place['lat'], place['lng']),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactTile({
    required Contact contact,
    required IconData icon,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        contact.fullName ?? 'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        contact.phoneNumbers?.first ?? 'No number',
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
      trailing: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.call_outlined,
            color: Colors.green,
            size: 20,
          ),
        ),
        onPressed: () {
          if (contact.phoneNumbers?.isNotEmpty ?? false) {
            _makeCall(contact.phoneNumbers!.first);
          }
        },
      ),
    );
  }

  IconData _getEmergencyServiceIcon(String service) {
    switch (service) {
      case 'Police':
        return Icons.local_police_outlined;
      case 'Women Helpline':
        return Icons.woman_outlined;
      case 'Ambulance':
        return Icons.medical_services_outlined;
      default:
        return Icons.emergency_outlined;
    }
  }

  Color _getEmergencyServiceColor(String service) {
    switch (service) {
      case 'Police':
        return Colors.blue;
      case 'Women Helpline':
        return Colors.purple;
      case 'Ambulance':
        return Colors.red;
      default:
        return primaryColor;
    }
  }
}
