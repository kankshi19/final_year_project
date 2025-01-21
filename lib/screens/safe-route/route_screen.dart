import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:safety_app/utils/constants.dart';
import '../../services/apis.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<Map<String, dynamic>> routes = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
  try {
    final response = await ApiService.fetchRoutes(
      startLat: widget.startLocation.latitude,
      startLng: widget.startLocation.longitude,
      endLat: widget.destinationLocation.latitude,
      endLng: widget.destinationLocation.longitude,
    );

    final currentTime = TimeOfDay.now(); // Current time to calculate time-based safety

    // Assuming historical incident rates are provided in the route data, if not, you'll need to adjust
    response.forEach((route) {
      double crowdDensity = route['crowd_density'] ?? 0.0;
      double historicalIncidentRate = route['historical_incident_rate'] ?? 0.0;
      
      // Calculate safety score using the RouteAnalyzer logic
      double safetyScore = RouteAnalyzer.calculateSafetyScore(
        crowdDensity: crowdDensity,
        currentTime: currentTime,
        historicalIncidentRate: historicalIncidentRate,
      );
      
      route['safety_score'] = safetyScore; // Add the calculated safety score to the route data
    });

    // Sort routes by safety score (highest to lowest)
    response.sort((a, b) => (b['safety_score'] ?? 0).compareTo(a['safety_score'] ?? 0));

    setState(() {
      routes = response;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      errorMessage = e.toString();
      isLoading = false;
    });
  }
}


  Color _getSafetyColor(double safetyScore) {
    if (safetyScore >= 80) return Colors.green;
    if (safetyScore >= 60) return Colors.yellow[700]!;
    if (safetyScore >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getSafetyIcon(double safetyScore) {
    if (safetyScore >= 80) return Icons.verified;
    if (safetyScore >= 60) return Icons.security;
    if (safetyScore >= 40) return Icons.warning;
    return Icons.dangerous;
  }

  Widget _buildSafetyIndicator(double safetyScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety Level',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: safetyScore / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getSafetyColor(safetyScore)),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          _getSafetyDescription(safetyScore),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getSafetyDescription(double safetyScore) {
    if (safetyScore >= 80) return 'Very Safe - Low crowd density';
    if (safetyScore >= 60) return 'Moderately Safe - Average crowd density';
    if (safetyScore >= 40) return 'Exercise Caution - High crowd density';
    return 'Use Alternative Route - Very high crowd density';
  }

  Widget _buildCrowdInfo(Map<String, dynamic> route) {
    
    final safetyScore = route['safety_score'] ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Current Crowd Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        _buildSafetyIndicator(safetyScore.toDouble()),
      ],
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, int index) {
    
    final safetyScore = route['safety_score'] ?? 0.0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getSafetyColor(safetyScore.toDouble()),
                  child: Icon(
                    _getSafetyIcon(safetyScore.toDouble()),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['route_name'] ?? 'Route ${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${route['duration_label'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Distance: ${route['distance_label'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Safety Score: ${safetyScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getSafetyColor(safetyScore.toDouble()),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildCrowdInfo(route),
            const SizedBox(height: 16),
            ElevatedButton(
  onPressed: () async {
    final url = route['direction_link'];
    print(url);
    
    if (url == null || url.isEmpty) {
      // Handle case where URL is null or empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Directions link is not available'),
        ),
      );
      return;
    }
    final Uri uri = Uri.parse(url as String);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Handle case where the URL cannot be launched
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open directions link'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 62, 170, 165),
    minimumSize: const Size(double.infinity, 48),
  ),
  child: const Text(
    'View Route Details',
    style: TextStyle(color: Colors.white),
  ),
)

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Routes'),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          _fetchRoutes();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : routes.isEmpty
                  ? const Center(
                      child: Text(
                        'No routes available',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: routes.length,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemBuilder: (context, index) {
                        return _buildRouteCard(routes[index], index);
                      },
                    ),
    );
  }
}