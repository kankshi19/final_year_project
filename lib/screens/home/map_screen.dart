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
  String _safety_score = "Fetching safety score...";
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
        return totalPlaces > 3 ? 1 : 0; // 0 = Nearby, 1 = Far
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
      if (weatherMain == 'Clear') {
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
      return Scaffold(
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
                      Icons.location_on_outlined,
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
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.white,
              child: Text("Safety Score : $_safety_score",
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
