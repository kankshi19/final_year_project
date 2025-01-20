// lib/services/route_analyzer.dart

import 'package:flutter/material.dart';

class RouteAnalyzer {
  static const double CROWD_WEIGHT = 0.5;
  static const double TIME_OF_DAY_WEIGHT = 0.3;
  static const double HISTORICAL_DATA_WEIGHT = 0.2;

  static double calculateSafetyScore({
    required double crowdDensity,
    required TimeOfDay currentTime,
    required double historicalIncidentRate,
  }) {
    double crowdScore = 1 - crowdDensity;
    double timeScore = _calculateTimeBasedScore(currentTime);
    double historicalScore = 1 - historicalIncidentRate;
    
    double safetyScore = (crowdScore * CROWD_WEIGHT) +
        (timeScore * TIME_OF_DAY_WEIGHT) +
        (historicalScore * HISTORICAL_DATA_WEIGHT);
        
    return safetyScore * 100;
  }

  static double _calculateTimeBasedScore(TimeOfDay time) {
    int hour = time.hour;
    
    if ((hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 19)) {
      return 0.6;
    } else if (hour >= 23 || hour <= 5) {
      return 0.4;
    } else {
      return 0.9;
    }
  }
}