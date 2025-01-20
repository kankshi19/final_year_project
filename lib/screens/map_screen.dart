import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation;
  late Location _location;
  String _zone = "Fetching zone...";
  final double _radius = 1000; // Radius in meters for the Google Places API query
  List<CircleMarker> _zoneMarkers = [];

  // Replace with your Google API key
  final String apiKey = "AIzaSyBNshGF10FPBnYO4oaYTnN2Lxuu580rxd8";

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
        await _fetchCrowdData(lat, lon);
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _fetchCrowdData(double lat, double lon) async {
    final String baseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    final Uri url = Uri.parse(
      "$baseUrl?location=$lat,$lon&radius=$_radius&key=$apiKey",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the response JSON
        final Map<String, dynamic> data = json.decode(response.body);

        // Analyze crowd data
        int totalPlaces = _analyzePlaces(data);

        // Determine the zone based on the number of nearby places
        String zone = _classifyZone(totalPlaces);

        setState(() {
          _zone = zone;
          _zoneMarkers = _createZoneMarkers(lat, lon, zone);
        });
      } else {
        print("Failed to fetch crowd data. Status code: ${response.statusCode}");
        setState(() {
          _zone = "Unable to fetch zone data.";
        });
      }
    } catch (e) {
      print("An error occurred while fetching crowd data: $e");
      setState(() {
        _zone = "Error fetching zone data.";
      });
    }
  }

  int _analyzePlaces(Map<String, dynamic> data) {
    // Analyze the number of places in the response
    if (data.containsKey("results")) {
      return data["results"].length;
    }
    return 0;
  }

  String _classifyZone(int totalPlaces) {
    if (totalPlaces < 5) {
      return "Red Zone (High Risk)";
    } else if (totalPlaces < 20) {
      return "Yellow Zone (Moderate Risk)";
    } else {
      return "Green Zone (Low Risk)";
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
        radius: _radius, // Radius in meters
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live location tracking'),
          backgroundColor: Color.fromARGB(255, 58, 156, 183),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    LatLng currentLatLng = LatLng(
      _currentLocation!.latitude ?? 0.0,
      _currentLocation!.longitude ?? 0.0,
    );

    return Scaffold(
      body: Stack(
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
                      Icons.location_on,
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
          Positioned(
            top: 16.0,
            left: 16.0,
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.white,
              child: Text(
                _zone,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
