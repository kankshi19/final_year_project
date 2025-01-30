import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:safety_app/utils/constants.dart';

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
  List<CircleMarker> _zoneMarkers = [];

  // Replace with your Google API key
  final String gmaps_apiKey = google_mapApiKey;

  @override
  void initState() {
    super.initState();
    _location = Location();
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
        await _fetchSafetyData(lat, lon);
      }
    } catch (e) {
      print("Error getting location: $e");
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
        print("tp: $totalPlaces");
        return totalPlaces > 5 ? 1 : 0; // 0 = Nearby, 1 = Far
      }
    } catch (e) {
      print("Error fetching neighborhood data: $e");
    }
    return 0;
  }

  Future<void> _fetchSafetyData(double lat, double lon) async {
    final Uri url = Uri.parse("https://vidhi91-miracle-space.hf.space/predict");

    int neighborhood = await _fetchNeighborhood(lat, lon);
    int crimeTime = DateTime.now().hour >= 18 ? 2 : 1;
    print(crimeTime);

    Map<String, dynamic> requestBody = {
      "crime_rate": await _fetchCrimeRate(lat, lon),
      "crime_time": crimeTime,
      "crowd_density": await _fetchCrowdDensity(lat, lon),
      "weather_condition_encoded": await _fetchWeather(lat, lon),
      "neighborhood": neighborhood,
      "longitude": lon,
      "latitude": lat,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _zone = data["zone"] ?? "Unknown Zone";
          _safety_score = data["safety_score"].toString() ?? "Unknown Safety";
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

  Future<double> _fetchCrimeRate(double lat, double lon) async {
    // Placeholder for fetching actual crime rate from an API or database
    return 2;
  }

  Future<int> _fetchCrowdDensity(double lat, double lon) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=$lat,$lon"
        "&radius=1000" // Search within 500m
        "&type=point_of_interest" // Consider specific place types if needed
        "&key=$gmaps_apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> places = data['results'];

        int crowdScore = 0;
        for (var place in places) {
          if (place.containsKey('user_ratings_total')) {
            crowdScore += place['user_ratings_total'] as int;
          }
        }

        // Normalize by number of places to avoid large values
        int densityEstimate = (places.length * 50) + (crowdScore ~/ (places.length + 1));
        print('Crowd density estimate: $densityEstimate');
        return densityEstimate;
        
      } else {
        throw Exception("Failed to fetch crowd data");
      }
    } catch (e) {
      print("Error fetching crowd density: $e");
      return -1; // Return a default or error value
    }
  }

  Future<int> _fetchWeather(double lat, double lon) async {
    final String weather_ApiKey = weatherApiKey;
    final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
    final Uri url = Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$weather_ApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String weatherMain = data['weather'][0]['main'];
        print(weatherMain);

        int weatherConditionEncoded;
        if (weatherMain == 'Clear' || weatherMain == 'Smoke') {
          weatherConditionEncoded = 0;
        } else if (weatherMain == 'Haze'||weatherMain == 'Clouds') {
          weatherConditionEncoded = 1;
        } else if (weatherMain == 'Rain') {
          weatherConditionEncoded = 2;
        } else {
          weatherConditionEncoded = 0; 
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
      onTap: () {
        // Add SOS functionality
      },
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
      if (numericScore >= 7.5) return Colors.green;
      if (numericScore >= 5) return Colors.orange;
      return Colors.red;
    } catch (e) {
      return Colors.grey; // For non-numeric or error cases
    }
  }
}