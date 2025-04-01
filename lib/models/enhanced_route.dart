import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/route_anlayzer.dart';

class EnhancedRoute {
  final String routeName;
  final String durationLabel;
  final String distanceLabel;
  final String directionsLink;
  final double safetyScore;
  final Map<String, dynamic> routeContext;

  EnhancedRoute({
    required this.routeName,
    required this.durationLabel,
    required this.distanceLabel,
    required this.directionsLink,
    required this.safetyScore,
    required this.routeContext,
  });

static Future<EnhancedRoute> fromRouteData(
  Map<String, dynamic> route, {
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  required String gmapsApiKey,
  required String weatherApiKey,
}) async {
  // Extract or decode route polyline to get route-specific points
  String polyline = route['polyline'] ?? '';
  List<Map<String, double>> routePoints = [];
  
  if (polyline.isNotEmpty) {
    // Decode the polyline to get actual coordinates for THIS specific route
    routePoints = decodePolyline(polyline).map((point) => {
      'lat': point.latitude, 
      'lng': point.longitude
    }).toList();
  } else if (route['coordinates'] != null) {
    // Use provided coordinates if available
    routePoints = (route['coordinates'] as List).cast<Map<String, double>>();
  }
  
  // Calculate THIS route's specific safety score based on ITS coordinates
  double safetyScore = 0;
  Map<String, dynamic> routeContext = {};
  
  if (routePoints.isNotEmpty) {
    // Sample points along THIS specific route
    List<Map<String, double>> sampledPoints = sampleRoutePoints(routePoints);
    
    // Calculate route-specific context parameters and safety scores
    double totalScore = 0;
    List<Map<String, dynamic>> pointContexts = [];
    
    for (var point in sampledPoints) {
      // Get context for this specific point on the route
      final pointContext = await RouteAnalyzer.fetchPointContext(
        lat: point['lat'] ?? 0,
        lng: point['lng'] ?? 0,
        gmapsApiKey: gmapsApiKey,
        weatherApiKey: weatherApiKey,
      );
      
      pointContexts.add(pointContext);
      
      // Calculate safety score for this point
      final pointScore = await RouteAnalyzer.fetchSafetyScore(
        crimeTime: pointContext['crime_time'],
        crowdDensity: pointContext['crowd_density'],
        weatherCondition: pointContext['weather_condition'],
        neighborhood: pointContext['neighborhood'], 
        lat: point['lat'] ?? 0, 
        lon: point['lng'] ?? 0, 
      );
      
      totalScore += pointScore;
    }
    
    // Calculate average safety score for THIS specific route
    safetyScore = totalScore / sampledPoints.length;
    
    // Create an aggregated route context from the sampled points
    routeContext = aggregateRouteContext(pointContexts);
  } else {
    // Fallback if no route points available
    routeContext = await RouteAnalyzer.fetchRouteContext(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      gmapsApiKey: gmapsApiKey,
      weatherApiKey: weatherApiKey,
    );
    
    safetyScore = await RouteAnalyzer.fetchSafetyScore(
      crimeTime: routeContext['crime_time'],
      crowdDensity: routeContext['crowd_density'],
      weatherCondition: routeContext['weather_condition'],
      neighborhood: routeContext['neighborhood'], 
      lat: (startLat + endLat) / 2, 
      lon: (startLng + endLng) / 2, 
    );
  }

  return EnhancedRoute(
    routeName: route['route_name'] ?? '',
    durationLabel: route['duration_label'] ?? '',
    distanceLabel: route['distance_label'] ?? '',
    directionsLink: route['direction_link'] ?? '',
    safetyScore: safetyScore * 10,
    routeContext: routeContext,
  );
}

// Helper method to aggregate context data from multiple points
static Map<String, dynamic> aggregateRouteContext(List<Map<String, dynamic>> pointContexts) {
  if (pointContexts.isEmpty) {
    return {
      'crowd_density': 50.0,
      'weather_condition': 0,
      'neighborhood': 0,
      'crime_time': DateTime.now().hour >= 22 ? 1 : 0,
    };
  }
  
  // Calculate averages for numerical values
  double avgCrowdDensity = 0;
  int totalWeatherCondition = 0;
  int totalNeighborhood = 0;
  
  for (var context in pointContexts) {
    avgCrowdDensity += (context['crowd_density'] as double);
    totalWeatherCondition += (context['weather_condition'] as int);
    totalNeighborhood += (context['neighborhood'] as int);
  }
  
  avgCrowdDensity /= pointContexts.length;
  
  // For weather and neighborhood, use the most common value
  // This is a simple approach - for a more sophisticated approach,
  // you could count occurrences and use the most frequent value
  int weatherCondition = (totalWeatherCondition / pointContexts.length).round();
  int neighborhood = (totalNeighborhood / pointContexts.length).round();
  
  return {
    'crowd_density': avgCrowdDensity,
    'weather_condition': weatherCondition,
    'neighborhood': neighborhood,
    'crime_time': DateTime.now().hour >= 22 ? 1 : 0,
  };
}

static List<Map<String, double>> sampleRoutePoints(List<Map<String, double>> coordinates) {
  if (coordinates.length <= 5) {
    // If we have 5 or fewer points, use all of them
    return coordinates;
  } else {
    // Sample a maximum of 5 points evenly distributed along the route
    List<Map<String, double>> sampledPoints = [];
    final int step = coordinates.length ~/ 5;
    
    for (int i = 0; i < coordinates.length; i += step) {
      if (sampledPoints.length < 5) {
        sampledPoints.add(coordinates[i]);
      }
    }
    
    // Always include the last point
    if (!sampledPoints.contains(coordinates.last)) {
      sampledPoints.add(coordinates.last);
    }
    
    return sampledPoints;
  }
}

// Helper function to decode polyline
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

    final latitude = lat / 1e5;
    final longitude = lng / 1e5;

    points.add(LatLng(latitude, longitude));
  }
  
  return points;
}
}