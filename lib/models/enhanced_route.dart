// lib/models/enhanced_route.dart

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

  factory EnhancedRoute.fromApiResponse(Map<String, dynamic> route) {
    double crowdDensity = route['crowd_density'] ?? 0.5;
    double historicalIncidentRate = route['historical_incident_rate'] ?? 0.3;
    
    double safetyScore = RouteAnalyzer.calculateSafetyScore(
      crowdDensity: crowdDensity,
      currentTime: TimeOfDay.now(),
      historicalIncidentRate: historicalIncidentRate,
    );

    return EnhancedRoute(
      routeName: route['route_name'] ?? '',
      durationLabel: route['duration_label'] ?? '',
      distanceLabel: route['distance_label'] ?? '',
      directionsLink: route['directions_link'] ?? '',
      safetyScore: safetyScore,
      crowdLevels: {}, // Populate with actual crowd data
    );
  }
}