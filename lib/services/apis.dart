import 'dart:async';
import 'dart:convert';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:http/http.dart' as http;

import '../models/enhanced_route.dart';

class ApiService {
  static const String apiKey = 'AIzaSyBNshGF10FPBnYO4oaYTnN2Lxuu580rxd8'; // Replace with your actual API key

  // Fetch search results (autocomplete)
  static Future<List<dynamic>> fetchSearchResults(String query) async {
    const String apiUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final Uri uri = Uri.parse(
        '$apiUrl?input=$query&radius=50000&language=en&key=$apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['predictions'];
      } else {
        throw Exception('Failed to fetch search results: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching search results: $e');
    }
  }

  // Fetch place details
  static Future<List<dynamic>> fetchPlaceDetails(String placeId) async {
    const String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json';
    final Uri uri = Uri.parse('$detailsUrl?place_id=$placeId&language=en&key=$apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final placeDetails = jsonDecode(response.body)['result'];
        final selectedLocation = GeoPoint(
          latitude: placeDetails['geometry']['location']['lat'],
          longitude: placeDetails['geometry']['location']['lng'],
        );
        return [selectedLocation, placeDetails];
      } else {
        throw Exception('Failed to fetch place details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching place details: $e');
    }
  }


static Future<List<Map<String, dynamic>>> fetchRoutes({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    const String rapidApiUrl = 'https://driving-directions1.p.rapidapi.com/get-directions';

    // Format coordinates as addresses (you might want to use reverse geocoding here)
    String origin = '$startLat, $startLng';  // Consider converting to address format
    String destination = '$endLat, $endLng';  // Consider converting to address format

    // Use queryParameters with Uri.https instead of manual string concatenation
    final uri = Uri.https('driving-directions1.p.rapidapi.com', '/get-directions', {
      'origin': origin,
      'destination': destination,
      'distance_units': 'auto',
      'avoid_routes': 'tolls,ferries',
      'country': 'in',
      'language': 'en',
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'x-rapidapi-host': 'driving-directions1.p.rapidapi.com',
          'x-rapidapi-key': 'a3fcd6647bmshc1a30e28106969bp19f41ajsn2d6a59ef2616',  
        },
      );

      if (response.statusCode == 200) {
        // Add debug print to see the raw response
        print('API Response: ${response.body}');
        
        final Map<String, dynamic> data = jsonDecode(response.body);

        // More detailed error checking
        if (data['status'] == null) {
          throw Exception('Invalid API response format: missing status field');
        }

        if (data['status'] != 'OK') {
          throw Exception('API request failed with status: ${data['status']} - ${data['message'] ?? 'No error message provided'}');
        }

        if (data['data']?['best_routes'] == null) {
          throw Exception('No routes found in response');
        }

        final bestRoutes = data['data']['best_routes'] as List;
        final direction_link = data['data']['directions_link'] ?? 'https://www.google.com/maps';

        return bestRoutes.map((route) => {
          'direction_link': direction_link,
          'origin': route['origin'] ?? '',
          'destination': route['destination'] ?? '',
          'route_name': route['route_name'] ?? '',
          'distance_label': route['distance_label'] ?? '',
          'duration_label': route['duration_label'] ?? '',
          // Add any additional fields you need
        }).toList();
      } else {
        print('Error Response: ${response.body}');  // Debug print
        throw Exception('Failed to fetch routes. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Exception caught: $e');  // Debug print
      throw Exception('Error fetching routes: $e');
    }
  }
  void testRoutes() async {
  try {
    final routes = await fetchRoutes(
      startLat: 37.7749,
      startLng: -122.4194,
      endLat: 37.3382,
      endLng: -121.8863,
    );
    print('Routes fetched successfully: $routes');
  } catch (e) {
    print('Error in test: $e');
  }
}
// static Future<List<EnhancedRoute>> fetchRoutesWithCrowdData({
//   required double startLat,
//   required double startLng,
//   required double endLat,
//   required double endLng,
// }) async {
//   final routes = await fetchRoutes(
//     startLat: startLat,
//     startLng: startLng,
//     endLat: endLat,
//     endLng: endLng,
//   );

//   // Process routes asynchronously
//   List<Future<EnhancedRoute>> enhancedRouteFutures = routes.map((route) async {
//     double latitude = route['latitude'] ?? 0.0;
//     double longitude = route['longitude'] ?? 0.0;

//     // Fetch real-time crowd and historical data
//     int crowdDensity = await RouteAnalyzer.fetchCrowdDensity(latitude, longitude);
//     double historicalIncidentRate = await RouteAnalyzer.fetchHistoricalIncidentRate(latitude, longitude);

//     // Create enhanced route with real data
//     Map<String, dynamic> enhancedRoute = {
//       ...route,
//       'crowd_density': crowdDensity.toDouble(),
//       'historical_incident_rate': historicalIncidentRate,
//     };

//     return await EnhancedRoute.fromApiResponse(enhancedRoute);
//   }).toList();

//   return await Future.wait(enhancedRouteFutures);
// }

  // Fetch directions polyline
  static Future<List<dynamic>> fetchDirections(
      GeoPoint startLocation, GeoPoint destinationLocation) async {
    const String directionsUrl =
        'https://maps.googleapis.com/maps/api/directions/json';

    final Uri uri = Uri.parse(
        '$directionsUrl?origin=${startLocation.latitude},${startLocation.longitude}'
        '&destination=${destinationLocation.latitude},${destinationLocation.longitude}'
        '&mode=driving&key=$apiKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['routes'][0]['overview_polyline']['points'];
      } else {
        throw Exception('Failed to fetch directions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching directions: $e');
    }
  }
}
