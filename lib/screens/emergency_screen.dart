import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
// import 'package:direct_caller_sim_choice/direct_caller_sim_choice.dart';

class EmergencyScreen extends StatefulWidget {
  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final List<Contact?> emergencyContacts = [];
  List<Map<String, dynamic>> nearbyPlaces = [];
  LocationData? _currentLocation;
  final Location location = Location();
  final String googleMapsApiKey = 'AIzaSyBNshGF10FPBnYO4oaYTnN2Lxuu580rxd8'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPredefinedContacts();
  }

  // Load predefined emergency contacts
  void _loadPredefinedContacts() {
    emergencyContacts.addAll([
      Contact(fullName: 'Police', phoneNumbers: ['100',]),
      Contact(fullName: 'Women Helpline', phoneNumbers: ['181',]),
      Contact(fullName: 'Ambulance', phoneNumbers: ['102']),
    ]);
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
    if (contact != null) {
      setState(() {
        emergencyContacts.add(contact);
        // Save to Firestore
        FirebaseFirestore.instance.collection('emergency_contacts').add({
          'name': contact.fullName,
          'phone': contact.phoneNumbers?.first,
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


  // Send an SOS message
 void _sendSOS() async {
  if (_currentLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to fetch current location')),
    );
    return;
  }

  final double latitude = _currentLocation!.latitude!;
  final double longitude = _currentLocation!.longitude!;
  final String locationUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
  final String message = 'Emergency! I need help. My location: $locationUrl';

  // Check if there are emergency contacts selected
  if (emergencyContacts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No emergency contacts selected')),
    );
    return;
  }

  try {
    // Send SMS to each emergency contact using flutter_sms
    // String result = await sendSMS(
    //   message: message,
    //   recipients: emergencyContacts.map((contact) => contact?.phoneNumbers?.first ?? '').toList(),
    //   sendDirect: true, // Sends directly without opening the SMS app
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SOS message sent to emergency contacts')),
    );

     // Optional: Check the result or log for success/failure
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send SOS message')),
    );
    debugPrint('Error sending SMS: $e');
  }
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
      // FirebaseFirestore.instance.collection('emergency_contacts').doc(contactId).delete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency & Nearby Support'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Emergency Contacts Section
            Card(
              margin: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: primaryColor),
                          onPressed: _addEmergencyContact,
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: emergencyContacts.length,
                    itemBuilder: (context, index) {
                      final contact = emergencyContacts[index];
                      return Dismissible(
                        key: Key(contact?.fullName ?? ''),
                        background: Container(color: Colors.red),
                        onDismissed: (direction) => _deleteContact(index),
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text(contact?.fullName ?? 'Unknown'),
                          subtitle:
                              Text(contact != null && contact.phoneNumbers!.isNotEmpty ? contact.phoneNumbers?.first ?? '' : 'No number'),
                          trailing: IconButton(
                            icon: Icon(Icons.call, color: primaryColor),
                            onPressed: () {
                              if (contact != null && contact.phoneNumbers!.isNotEmpty) {
                                final String phoneNumber = contact.phoneNumbers!.first;
                                _makeCall(phoneNumber);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _sendSOS,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: Text('Send SOS'),
                    ),
                  ),
                ],
              ),
            ),
            // Nearby Places Section
            Card(
              margin: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'Nearby Support Centers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: nearbyPlaces.length,
                    itemBuilder: (context, index) {
                      final place = nearbyPlaces[index];
                      return ListTile(
                        leading:
                            CircleAvatar(child: Icon(Icons.place)),
                        title:
                            Text(place['name']),

                        trailing:
                            IconButton(icon:
                                Icon(Icons.directions, color:
                                    primaryColor), onPressed:
                                () => _openGoogleMaps(place['lat'], place['lng'])),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
