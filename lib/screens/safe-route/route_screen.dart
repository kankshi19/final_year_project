import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:safety_app/utils/constants.dart';
import '../../services/apis.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/route_anlayzer.dart';

class RouteScreen extends StatefulWidget {
  final GeoPoint startLocation;
  final GeoPoint destinationLocation;

  const RouteScreen({
    Key? key,
    required this.startLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  bool isLoading = true;
  String? errorMessage;
  double finalSafetyScore = 0.0;

  @override
  void initState() {
    super.initState();
    _analyzeRoute();
  }

Future<void> _analyzeRoute() async {
  try {
    // Debugging: Print start and destination locations
    print("Start Location: ${widget.startLocation}");
    print("Destination Location: ${widget.destinationLocation}");

    if (widget.startLocation == null || widget.destinationLocation == null) {
      throw Exception("Start or destination location is null.");
    }

    // Fetch route coordinates
    List<dynamic>? coordinates = await ApiService.fetchRoutes(
      startLat: widget.startLocation.latitude,
      startLng: widget.startLocation.longitude,
      endLat: widget.destinationLocation.latitude,
      endLng: widget.destinationLocation.longitude,
    );

    // Debugging: Check if coordinates are fetched
    if (coordinates == null || coordinates.isEmpty) {
      throw Exception("No route coordinates received.");
    }
    print("Fetched Coordinates: $coordinates");

    List<Map<String, dynamic>> coordinateData = [];

    for (var coord in coordinates) {
      // Ensure coord has latitude and longitude
      if (coord == null || coord.latitude == null || coord.longitude == null) {
        throw Exception("Invalid coordinate data: $coord");
      }

      double crimeTime = DateTime.now().hour >= 18 ? 1.0 : 0.0;

      // Fetch weather condition
      var weatherResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${coord.latitude}&lon=${coord.longitude}&appid=YOUR_API_KEY'));
      var weatherData = jsonDecode(weatherResponse.body);
      double weatherCondition = (weatherData['weather'][0]['main'] == 'Clear') ? 0.0 : 1.0;

      // Fetch crowd density
      var crowdResponse = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${coord.latitude},${coord.longitude}&radius=500&type=establishment&key=YOUR_API_KEY'));
      var crowdData = jsonDecode(crowdResponse.body);
      double crowdDensity = (crowdData['results'] as List).length.clamp(1, 100).toDouble();

      // Determine neighborhood status
      double neighborhoodStatus = crowdDensity > 10 ? 0.0 : 1.0;

      coordinateData.add({
        'crimeTime': crimeTime,
        'weatherCondition': weatherCondition,
        'crowdDensity': crowdDensity,
        'neighborhood': neighborhoodStatus,
        'latitude': coord.latitude,
        'longitude': coord.longitude,
      });
    }

    // Debugging: Check collected coordinate data
    print("Processed Coordinate Data: $coordinateData");

    // Predict safety scores using first model
    List<Future<double>> safetyScoreFutures = coordinateData.map((data) async {
      int neighborhood = await RouteAnalyzer.fetchNeighborhood(data['latitude'], data['longitude']);
      int weatherCondition = await RouteAnalyzer.fetchWeather(data['latitude'], data['longitude']);
      int crowdDensity = await RouteAnalyzer.fetchCrowdDensity(data['latitude'], data['longitude']);

      return RouteAnalyzer.predictSafetyScore(
        crimeTime: data['crimeTime'],
        weatherCondition: weatherCondition,
        crowdDensity: crowdDensity,
        neighborhood: neighborhood,
        latitude: data['latitude'],
        longitude: data['longitude'],
      );
    }).toList();

    List<double> safetyScores = await Future.wait(safetyScoreFutures);

    // Compute final safety score
    finalSafetyScore = safetyScores.reduce((a, b) => a + b) / safetyScores.length;

    setState(() {
      isLoading = false;
    });

    // Debugging: Log final safety score
    print("Final Safety Score: $finalSafetyScore");

  } catch (e, stackTrace) {
    print("Error: $e");
    print(stackTrace);
    setState(() {
      errorMessage = e.toString();
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Safety Analysis'),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Final Safety Score: ${finalSafetyScore.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final Uri uri = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&origin=${widget.startLocation.latitude},${widget.startLocation.longitude}&destination=${widget.destinationLocation.latitude},${widget.destinationLocation.longitude}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: const Text('View Route on Google Maps'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
