import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteAnalyzer {
  static const String _safetyScoreApiUrl = 'https://helishah12-miracle-space.hf.space/predict/';

  /// Fetch safety score from external API
  static Future<double> fetchSafetyScore({
    required int crimeTime,
    required double crowdDensity,
    required int weatherCondition,
    required int neighborhood,
    required dynamic lat,
    required dynamic lon,
    
  }) async {
    try {
       Map<String, dynamic> requestBody = {
    "latitude": lat,
    "longitude": lon,
    "crime_time": crimeTime,
    "crowd_density": crowdDensity,
    "weather_condition_encoded": weatherCondition,
    "neighborhood": neighborhood,
  };

      final response = await http.post(
        Uri.parse(_safetyScoreApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['safety_score']?.toDouble() ?? 0.0;
      } else {
        print('Safety Score API Error: ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('Safety Score Fetch Error: $e');
      return 0.0;
    }
  }

  /// Fetch context for a specific point on the route
  static Future<Map<String, dynamic>> fetchPointContext({
    required double lat,
    required double lng,
    required String gmapsApiKey,
    required String weatherApiKey,
  }) async {
    try {
      // Fetch parameters for this specific point
      final crowdDensity = await fetchCrowdDensity(lat, lng, gmapsApiKey);
      final weatherCondition = await fetchWeather(lat, lng, weatherApiKey);
      final neighborhood = await fetchNeighborhood(lat, lng, gmapsApiKey);

      return {
        'crowd_density': crowdDensity.toDouble(),
        'weather_condition': weatherCondition,
        'neighborhood': neighborhood,
        'crime_time': DateTime.now().hour >= 22 ? 1 : 0,
      };
    } catch (e) {
      print('Point Context Fetch Error: $e');
      return {
        'crowd_density': 50.0,
        'weather_condition': 0,
        'neighborhood': 0,
        'crime_time': DateTime.now().hour >= 22 ? 1 : 0,
      };
    }
  }

  /// Fetch crowd density using Google Places API
  static Future<int> fetchCrowdDensity(double lat, double lon, String gmapsApiKey) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=$lat,$lon"
        "&radius=1000"
        "&type=point_of_interest"
        "&key=$gmapsApiKey";

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

        const int estimatedMaxCrowd = 2500;
        int rawDensity = totalUserRatings ~/ (totalPlaces + 1);

        int normalizedDensity = ((rawDensity * 100) ~/ estimatedMaxCrowd).clamp(1, 100);

        // print('Crowd density estimate (1-100%): $normalizedDensity');
        return normalizedDensity;
      } else {
        throw Exception("Failed to fetch crowd data");
      }
    } catch (e) {
      print("Error fetching crowd density: $e");
      return 1;
    }
  }

  /// Fetch weather condition using OpenWeatherMap API
  static Future<int> fetchWeather(double lat, double lon, String weatherApiKey) async {
    final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
    final Uri url = Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$weatherApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String weatherMain = data['weather'][0]['main'];

        int weatherConditionEncoded;
        if (weatherMain == 'Clear') {
          weatherConditionEncoded = 0;
        } else {
          weatherConditionEncoded = 1; 
        }
        // print('Weather condition encoded: $weatherConditionEncoded');
        return weatherConditionEncoded;
      } else {
        print('Failed to fetch weather data. Status code: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return 0;
    }
  }

  /// Fetch neighborhood context using Google Places API
  static Future<int> fetchNeighborhood(double lat, double lon, String gmapsApiKey, {double radius = 1000}) async {
    final String baseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    final Uri url = Uri.parse("$baseUrl?location=$lat,$lon&radius=$radius&key=$gmapsApiKey");
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        int totalPlaces = data["results"].length;
        // print("total places: $totalPlaces");
        return totalPlaces > 5 ? 0 : 1;
      }
    } catch (e) {
      print("Error fetching neighborhood data: $e");
    }
    return 0;
  }

  /// Fetch real-time context for safety score calculation
  static Future<Map<String, dynamic>> fetchRouteContext({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String gmapsApiKey,
    required String weatherApiKey,
  }) async {
    try {
      // Calculate midpoint for context gathering
      final midLat = (startLat + endLat) / 2;
      final midLng = (startLng + endLng) / 2;

      // Fetch real-time parameters
      final crowdDensity = await fetchCrowdDensity(midLat, midLng, gmapsApiKey);
      final weatherCondition = await fetchWeather(midLat, midLng, weatherApiKey);
      final neighborhood = await fetchNeighborhood(midLat, midLng, gmapsApiKey);

      return {
        'crowd_density': crowdDensity.toDouble(),
        'weather_condition': weatherCondition,
        'neighborhood': neighborhood,
        'crime_time': DateTime.now().hour >= 22 ? 1 : 0,
      };
    } catch (e) {
      print('Route Context Fetch Error: $e');
      return {
        'crowd_density': 50.0,
        'weather_condition': 2,
        'neighborhood': 3,
        'crime_time': DateTime.now().hour >= 22 ? 1 : 0,
      };
    }
  }
}