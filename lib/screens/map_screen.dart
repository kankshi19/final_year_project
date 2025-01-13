import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart'; // Ensure this package is imported
import 'package:location/location.dart';

import '../routes/app_routes.dart'; // Import the location package
 
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}
 
class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation; // Store the current location
  late Location _location; // Instance of the Location class
  String _zone = "Fetching zone..."; // Default zone text
  final double _radius = 10; // Radius in meters for the Overpass API query
 
  @override
  void initState() {
    super.initState();
    _location = Location(); // Initialize the location package
    _getCurrentLocation(); // Fetch the current location
  }
 
  // Function to fetch the current location
  Future<void> _getCurrentLocation() async {
    try {
      var location = await _location.getLocation();
      setState(() {
        _currentLocation = location;
      });
 
      // Fetch population data and determine the zone
      if (_currentLocation != null) {
        double lat = _currentLocation!.latitude!;
        double lon = _currentLocation!.longitude!;
        await _fetchZoneData(lat, lon);
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }
 
  // Function to fetch population data from Overpass API
  Future<void> _fetchZoneData(double lat, double lon) async {
    final url = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=[out:json];node(around:$_radius,$lat,$lon)["population"];out;');
 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int population = _analyzePopulation(data);
        String zone = _classifyZone(population);
 
        setState(() {
          _zone = zone;
        });
      } else {
        print("Error: ${response.statusCode}");
        setState(() {
          _zone = "Unable to fetch zone data.";
        });
      }
    } catch (e) {
      print("Error fetching population data: $e");
      setState(() {
        _zone = "Error fetching zone data.";
      });
    }
  }
 
  // Analyze population data to calculate total population
  int _analyzePopulation(Map<String, dynamic> data) {
    int totalPopulation = 0;
    if (data.containsKey("elements")) {
      for (var element in data["elements"]) {
        if (element["tags"] != null && element["tags"]["population"] != null) {
          totalPopulation += int.tryParse(element["tags"]["population"]) ?? 0;
        }
      }
    }
    return totalPopulation;
  }
 
  // Classify zone based on population
  String _classifyZone(int population) {
    if (population > 20) {
      return "Green Zone (High Population)";
    } else if (population > 10) {
      return "Yellow Zone (Moderate Population)";
    } else {
      return "Red Zone (Low Population)";
    }
  }
 
  @override
@override
Widget build(BuildContext context) {
  if (_currentLocation == null) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location...'),
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
        SizedBox(height: 20,),
        // Wrap FlutterMap in an Expanded or SizedBox with a fixed height
        Expanded(
          child: FlutterMap(
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
            ],
          ),
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