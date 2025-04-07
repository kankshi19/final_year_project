import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:safety_app/services/notification_service.dart';
import 'package:safety_app/utils/constants.dart';

import '../../services/bleService.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation;
  late Location _location;
  String _zone = "Fetching zone...";
  String _safety_score = "0.0..";
  final double _radius = 200;

  int _countdown = 10;
  Timer? _timer;
  final BleService _bleService = BleService();
  bool _isSending = false;
  String _sosStatus = "";
  bool _isWearableConnected = false;


  List<CircleMarker> _zoneMarkers = [];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _user;

  // Replace with your Google API key
  final String gmaps_apiKey = google_mapApiKey;

  StreamSubscription<String>? _connectionSubscription;

  void _startCountdown(BuildContext context) {
  _countdown = 5; 

  // Show the enhanced confirmation dialog first
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing by tapping outside
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Start the countdown timer after building the dialog
          // This ensures the timer updates the UI using setDialogState
          if (_timer == null || !_timer!.isActive) {
            _timer = Timer.periodic(Duration(seconds: 1), (timer) {
              setDialogState(() {
                if (_countdown > 0) {
                  _countdown--;
                } else {
                  _triggerSOS();
                  timer.cancel();
                  Navigator.of(context).pop(); // Close dialog after triggering SOS
                }
              });
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.red.shade50,
            title: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  "EMERGENCY SOS",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your emergency contacts will be notified",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      "$_countdown",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _countdown / 5, // Progress based on countdown
                  backgroundColor: Colors.red.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  "Sending SOS in $_countdown ${_countdown == 1 ? 'second' : 'seconds'}...",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "I'M SAFE - CANCEL SOS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
            actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          );
        },
      );
    },
  );
}

  void _triggerSOS() {
    Navigator.pop(context); // Close the dialog
    
    setState(() {
      _isSending = true;
      _sosStatus = "Sending SOS signal...";
    });
    
    // Use BleService to trigger SOS
    _bleService.triggerSOS().then((success) {
      setState(() {
        _isSending = false;
        _sosStatus = success 
            ? "SOS signal sent successfully!" 
            : "Failed to send SOS. Using cloud backup.";
      });
      
      // Also send to Firebase as backup
      sendSOS();
      
      // Show result notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_sosStatus),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }).catchError((error) {
      setState(() {
        _isSending = false;
        _sosStatus = "Error: Using cloud backup";
      });
      
      // Fallback to Firebase
      sendSOS();
    });
  }

void _checkBleConnection() async {
  if (!_bleService.isConnected) {
    await _bleService.scanAndConnect();
  }
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
    // Initialize connection status
    _isWearableConnected = _bleService.isConnected;
    
    // Subscribe to connection status updates
    _connectionSubscription = _bleService.connectionStatusStream.listen((status) {
      setState(() {
        _isWearableConnected = status == "Connected";
      });
    });
    _location = Location();
    _user = FirebaseAuth.instance.currentUser;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var location = await _location.getLocation();
      setState(() {
        _currentLocation = location;
      });

      if (_currentLocation != null) {
        double lat = _currentLocation!.latitude!;
        double lon = _currentLocation!.longitude!;

        // Store location in Firebase
        _updateLocationInFirebase(lat, lon);

        await _fetchSafetyData(lat, lon);
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _updateLocationInFirebase(double latitude, double longitude) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("users/$userId/location");
      ref.set({
        "latitude": latitude,
        "longitude": longitude,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      }).then((_) {
        print("✅ Location updated in Firebase!");
      }).catchError((error) {
        print("❌ Failed to update location: $error");
      });
    }
  }


  Future<int> _fetchNeighborhood(double lat, double lon) async {
    final String baseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    final Uri url = Uri.parse("$baseUrl?location=$lat,$lon&radius=$_radius&key=$gmaps_apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        int totalPlaces = data["results"].length;
        print("total places: $totalPlaces");
        return totalPlaces > 5 ? 0 : 1; // 0 = Nearby, 1 = Far
      }
    } catch (e) {
      print("Error fetching neighborhood data: $e");
    }
    return 0;
  }

Future<void> _fetchSafetyData(double lat, double lon) async {
  final Uri url = Uri.parse("https://helishah12-miracle-space.hf.space/predict/");

  int neighborhood = await _fetchNeighborhood(lat, lon);
  double crimeTime = DateTime.now().hour >= 18 ? 1 : 0;

  Map<String, dynamic> requestBody = {
    "latitude": lat,
    "longitude": lon,
    "crime_time": crimeTime,
    "crowd_density": await _fetchCrowdDensity(lat, lon),
    "weather_condition_encoded": await _fetchWeather(lat, lon),
    "neighborhood": neighborhood,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      // double crime_rate = data["crime_rate_prediction"] ?? 0.0;
      double safetyScore = data['safety_score'] is int
    ? (data['safety_score'] as int).toDouble()
    : (data['safety_score'] as double);

      
      String zone;
      if (safetyScore >= 7) {
        zone = "Green (Safe)";
      } else if (safetyScore >= 4) {
        zone = "Yellow (Moderate Safety)";
      } else {
        zone = "Red (Unsafe)";
      }

      NotificationService.showZoneAlert(zone: zone, safetyScore: safetyScore);

      setState(() {
        _safety_score = safetyScore.toString();
        _zone = zone;
        _zoneMarkers = _createZoneMarkers(lat, lon, _zone);
      });

    } else {
      print("Failed to fetch safety data. Status code: ${response.statusCode}");
      setState(() {
        _zone = "Unable to fetch safety data.";
      });
    }
  } catch (e) {
    print("An error occurred while fetching safety data: $e");
    setState(() {
      _zone = "Error fetching safety data.";
    });
  }
}


  // Future<double> _fetchCrimeRate(double lat, double lon) async {
  //   // Placeholder for fetching actual crime rate from an API or database
  //   return 2;
  // }

  Future<int> _fetchCrowdDensity(double lat, double lon) async {
  final String url =
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
      "?location=$lat,$lon"
      "&radius=1000" 
      "&type=point_of_interest" // General POIs, can be adjusted
      "&key=$gmaps_apiKey";

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> places = data['results'];

      if (places.isEmpty) {
        return 1; // No crowd if no places are found
      }

      int totalUserRatings = 0;
      int totalPlaces = places.length;

      for (var place in places) {
        if (place.containsKey('user_ratings_total')) {
          totalUserRatings += place['user_ratings_total'] as int;
        }
      }

      // Define a dynamic max crowd score based on past observations (Adjust this based on real-world data)
      const int estimatedMaxCrowd = 2500; // Assume 1000+ people in a 500m circle is extreme
      int rawDensity = totalUserRatings ~/ (totalPlaces + 1); // Avoid division by zero

      // Normalize to a scale of 1-100% (how full the area is)
      int normalizedDensity = ((rawDensity * 100) ~/ estimatedMaxCrowd).clamp(1, 100);

      print('Crowd density estimate (1-100%): $normalizedDensity');
      return normalizedDensity;
    } else {
      throw Exception("Failed to fetch crowd data");
    }
  } catch (e) {
    print("Error fetching crowd density: $e");
    return 1; // Return minimum value on error
  }
}

  Future<int> _fetchWeather(double lat, double lon) async {
    final String weather_ApiKey = weatherApiKey;
    final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
    final Uri url = Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$weather_ApiKey');
    print(url);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String weatherMain = data['weather'][0]['main'];
        print(weatherMain);

        int weatherConditionEncoded;
        if (weatherMain == 'Clear') {
          weatherConditionEncoded = 0;
        }else {
          weatherConditionEncoded = 1; 
        }
        print('Weather condition encoded: $weatherConditionEncoded');
        return weatherConditionEncoded;
      } else {
        print('Failed to fetch weather data. Status code: ${response.statusCode}');
        return 0; // Default to 'Cloudy' if fetch fails
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return 0; // Default to 'Cloudy' in case of error
    }
  }

  List<CircleMarker> _createZoneMarkers(double lat, double lon, String zone) {
    Color color;
    if (zone.contains("Red")) {
      color = Colors.red.withOpacity(0.3);
    } else if (zone.contains("Yellow")) {
      color = Colors.yellow.withOpacity(0.3);
    } else {
      color = Colors.green.withOpacity(0.3);
    }

    return [
      CircleMarker(
        point: LatLng(lat, lon),
        color: color,
        borderColor: Colors.black,
        borderStrokeWidth: 1.0,
        useRadiusInMeter: true,
        radius: _radius,
      ),
    ];
  }


  void updateUserLocation(String userId, double lat, double lon) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users/$userId/location");

    ref.set({
      "latitude": lat,
      "longitude": lon,
      "timestamp": ServerValue.timestamp
    }).then((_) {
      print("Location updated successfully!");
    }).catchError((error) {
      print("Failed to update location: $error");
    });
  }




  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    LatLng currentLatLng = LatLng(
      _currentLocation!.latitude ?? 0.0,
      _currentLocation!.longitude ?? 0.0,
    );

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: currentLatLng,
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLatLng,
                  width: 40.0,
                  height: 40.0,
                  child: Icon(
                    Icons.location_on_sharp,
                    color: Colors.red,
                    size: 40.0,
                  ),
                ),
              ],
            ),
            CircleLayer(
              circles: _zoneMarkers,
            ),
          ],
        ),
        // Safety Information Card
        Positioned(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          child: Card(
            elevation: 4,
            color: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _zone.contains("Red") 
                            ? Icons.warning 
                            : _zone.contains("Yellow")
                                ? Icons.info
                                : Icons.check_circle,
                        color: _zone.contains("Red")
                            ? Colors.red
                            : _zone.contains("Yellow")
                                ? Colors.orange
                                : Colors.green,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _zone,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Current Area Status",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Safety Score",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _safety_score,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getSafetyScoreColor(_safety_score),
                            ),
                          ),
                        ],
                      ),
                      _buildQuickSOSButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // // Quick Actions Row
        // Positioned(
        //   bottom: 16.0,
        //   left: 16.0,
        //   right: 16.0,
        //   child: Container(
        //     height: 80,
        //     child: ListView(
        //       scrollDirection: Axis.horizontal,
        //       children: [
        //         _buildActionCard(
        //           icon: Icons.share_location,
        //           label: 'Share\nLocation',
        //           color: Color(0xFF3EAAA5),
        //           onTap: () {
        //             // Add location sharing functionality
        //           },
        //         ),
        //         _buildActionCard(
        //           icon: Icons.family_restroom,
        //           label: 'Trusted\nContacts',
        //           color: Color(0xFF3EAAA5),
        //           onTap: () {
        //             // Add trusted contacts functionality
        //           },
        //         ),
        //         _buildActionCard(
        //           icon: Icons.local_hospital,
        //           label: 'Emergency\nServices',
        //           color: Color(0xFF3EAAA5),
        //           onTap: () {
        //             // Add emergency services functionality
        //           },
        //         ),
        //         _buildActionCard(
        //           icon: Icons.local_police,
        //           label: 'Nearby\nPolice',
        //           color: Color(0xFF3EAAA5),
        //           onTap: () {
        //             // Add nearby police functionality
        //           },
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildQuickSOSButton() {
    return GestureDetector(
      onDoubleTap: _isSending ? null : () => _startCountdown(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSafetyScoreColor(String score) {
    try {
      double numericScore = double.parse(score);
      if (numericScore >= 7) return Colors.green;
      if (numericScore >= 4) return Colors.orange;
      return Colors.red;
    } catch (e) {
      return Colors.grey; // For non-numeric or error cases
    }
  }
}