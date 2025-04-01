import 'dart:async';
import 'dart:convert';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/enhanced_route.dart';
import '../utils/constants.dart';

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
  required String apiKey,
}) async {
  // This uses the classic Directions API, matching the JavaScript example
  final String directionsApiUrl = 'maps.googleapis.com';
  final String endpoint = 'maps/api/directions/json';

  // Build query parameters
  final Map<String, String> queryParams = {
    'origin': '$startLat,$startLng',
    'destination': '$endLat,$endLng',
    'mode': 'driving|walking|bicycling|transit',
    'alternatives': 'true',  // Include alternative routes
    'key': apiKey,
  };

  // Create URI with API key and params
  final uri = Uri.https(directionsApiUrl, endpoint, queryParams);

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // Add debug print to see the raw response
      print('API Response: ${response.body}');
      
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Check if the request was successful
      if (data['status'] != 'OK') {
        throw Exception('API request failed with status: ${data['status']} - ${data['error_message'] ?? 'No error message provided'}');
      }

      // Check if routes are available
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        throw Exception('No routes found in response');
      }

      final routes = data['routes'] as List;
      
      return routes.map((route) {
        // Extract leg information (typically just one leg for simple directions)
        final leg = route['legs'][0];
        final distance = leg['distance']['text'];
        final duration = leg['duration']['text'];
        
        // Extract route polyline
        final overviewPolyline = route['overview_polyline']['points'];
        
        // Extract steps coordinates (similar to the JS version)
        List<Map<String, double>> coordinates = [];
        
        // Process steps to extract coordinates (similar to the JS code)
        for (var step in leg['steps']) {
          if (step['polyline'] != null && step['polyline']['points'] != null) {
            // The actual steps would need polyline decoding for precise coordinates
            // For demo, we'll use the start and end points of each step
            coordinates.add({
              'lat': step['start_location']['lat'],
              'lng': step['start_location']['lng'],
            });
            coordinates.add({
              'lat': step['end_location']['lat'],
              'lng': step['end_location']['lng'],
            });
          }
        }
        
        // Create a Google Maps direction link
        final directionLink = 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving';
        
        return {
          'direction_link': directionLink,
          'origin': '$startLat, $startLng',
          'destination': '$endLat, $endLng',
          'route_name': route['summary'] ?? 'Route',
          'distance_label': distance,
          'duration_label': duration,
          'polyline': overviewPolyline,
          'coordinates': coordinates,
          // Add any additional fields you need
        };
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
      apiKey: 'YOUR_API_KEY', // Replace with your variable
    );
    print('Routes fetched successfully: $routes');
  } catch (e) {
    print('Error in test: $e');
  }
}
static Future<List<EnhancedRoute>> fetchEnhancedRoutes({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  required String gmapsApiKey,
  required String weatherApiKey,
}) async {
  // First, fetch the raw routes from Google Maps API
  final rawRoutes = await fetchRoutes(
    startLat: startLat,
    startLng: startLng,
    endLat: endLat,
    endLng: endLng,
    apiKey: gmapsApiKey,
  );
  
  // Now enhance each route with safety scores
  List<EnhancedRoute> enhancedRoutes = [];
  
  for (var route in rawRoutes) {
    final enhancedRoute = await EnhancedRoute.fromRouteData(
      route,
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      gmapsApiKey: gmapsApiKey,
      weatherApiKey: weatherApiKey,
    );
    
    enhancedRoutes.add(enhancedRoute);
  }
  
  return enhancedRoutes;
}

// Fetch directions polyline
static Future<String> fetchDirections(
  GeoPoint startLocation, 
  GeoPoint destinationLocation
) async {
  const String directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';

   final Uri uri = Uri.parse(
    '$directionsUrl?origin=${startLocation.latitude},${startLocation.longitude}'
    '&destination=${destinationLocation.latitude},${destinationLocation.longitude}'
    '&mode=driving&alternatives=true&key=$apiKey'
  );

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if the request was successful
      if (data['status'] != 'OK') {
        throw Exception('API request failed with status: ${data['status']} - ${data['error_message'] ?? 'No error message provided'}');
      }
      
      // Return the polyline points for the first route
      return data['routes'][0]['overview_polyline']['points'];
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching directions: $e');
  }
}

// If you want to get polylines for all alternative routes, use this function instead
static Future<List<String>> fetchAllRoutePolylines(
  GeoPoint startLocation, 
  GeoPoint destinationLocation
) async {
  const String directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  final Uri uri = Uri.parse(
    '$directionsUrl?origin=${startLocation.latitude},${startLocation.longitude}'
    '&destination=${destinationLocation.latitude},${destinationLocation.longitude}'
    '&mode=driving&alternatives=true&key=$apiKey'
  );

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if the request was successful
      if (data['status'] != 'OK') {
        throw Exception('API request failed with status: ${data['status']} - ${data['error_message'] ?? 'No error message provided'}');
      }
      
      // Extract polylines from all routes
      final routes = data['routes'] as List;
      return routes.map<String>((route) => 
        route['overview_polyline']['points'] as String
      ).toList();
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching directions: $e');
  }
}

// Helper function to decode polyline points (if you need coordinates)
static List<LatLng> decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    double latitude = lat / 1e5;
    double longitude = lng / 1e5;

    points.add(LatLng(latitude, longitude));
  }
  return points;
}
}
