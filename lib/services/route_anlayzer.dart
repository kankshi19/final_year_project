import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class RouteAnalyzer {
  static const String _predictionApiUrl = "https://helishah12-miracle-space.hf.space/predict/";
  static const String gmaps_apiKey = google_mapApiKey;
  static const String _weatherApiKey = weatherApiKey;

  static Future<double> predictSafetyScore({
    required double latitude,
    required double longitude,
    required double crimeTime,
    required int weatherCondition,
    required int crowdDensity,
    required int neighborhood,
  }) async {
    try {
      Map<String, dynamic> requestBody = {
        "latitude": latitude,
        "longitude": longitude,
        "crime_time": crimeTime,
        "crowd_density": crowdDensity,
        "weather_condition_encoded": weatherCondition,
        "neighborhood": neighborhood,
      };

      final response = await http.post(
        Uri.parse(_predictionApiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        double safetyScore = (data['safety_score'] as num).toDouble(); // ✅ Explicit type cast

        return safetyScore;
      } else {
        print("Failed to fetch safety score. Status code: ${response.statusCode}");
        return 0.0;
      }
    } catch (e) {
      print("Error predicting safety score: $e");
      return 0.0;
    }
  }

  static Future<int> fetchNeighborhood(double lat, double lon) async {
    final String baseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    final Uri url = Uri.parse("$baseUrl?location=$lat,$lon&radius=1000&key=$gmaps_apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        int totalPlaces = data["results"].length;
        return (totalPlaces > 5 ? 0 : 1).toInt(); // ✅ Explicit type cast
      }
    } catch (e) {
      print("Error fetching neighborhood data: $e");
    }
    return 0;
  }

  static Future<int> fetchWeather(double lat, double lon) async {
    final Uri url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String weatherMain = data['weather'][0]['main'];

        return (weatherMain == 'Clear' ? 0 : 1).toInt(); // ✅ Explicit type cast
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
    return 1;
  }

    static Future<int> fetchCrowdDensity(double lat, double lon) async {
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

}
