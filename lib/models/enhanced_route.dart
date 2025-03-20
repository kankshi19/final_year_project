import 'package:flutter/material.dart';
import '../services/route_anlayzer.dart';

class EnhancedRoute {
  final String routeName;
  final String durationLabel;
  final String distanceLabel;
  final String directionsLink;
  final double safetyScore;
  final Map<String, double> crowdLevels;

  EnhancedRoute({
    required this.routeName,
    required this.durationLabel,
    required this.distanceLabel,
    required this.directionsLink,
    required this.safetyScore,
    required this.crowdLevels,
  });

  static Future<EnhancedRoute> fromApiResponse(Map<String, dynamic> route) async {
    double latitude = route['latitude'] ?? 0.0;
    double longitude = route['longitude'] ?? 0.0;

    // Fetch additional data
    int neighborhood = await RouteAnalyzer.fetchNeighborhood(latitude, longitude);
    int weatherCondition = await RouteAnalyzer.fetchWeather(latitude, longitude);
    int crowdDensity = await RouteAnalyzer.fetchCrowdDensity(latitude, longitude);

    // Calculate safety score
    double safetyScore = await RouteAnalyzer.predictSafetyScore(
      crimeTime: TimeOfDay.now().hour.toDouble(),
      weatherCondition: weatherCondition,
      crowdDensity: crowdDensity,
      neighborhood: neighborhood,
      latitude: latitude,
      longitude: longitude,
    );

    return EnhancedRoute(
      routeName: route['route_name'] ?? '',
      durationLabel: route['duration_label'] ?? '',
      distanceLabel: route['distance_label'] ?? '',
      directionsLink: route['directions_link'] ?? '',
      safetyScore: safetyScore,
      crowdLevels: {
        'crowd_density': crowdDensity.toDouble(),
        'neighborhood': neighborhood.toDouble(),
        'weather_condition': weatherCondition.toDouble(),
      },
    );
  }
}
