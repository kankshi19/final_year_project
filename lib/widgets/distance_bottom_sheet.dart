import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

import '../screens/route_screen.dart';

class DistanceBottomSheet extends StatelessWidget {
  final dynamic placeDetails; // Details fetched from the API
  final GeoPoint? startLocation; // Starting point
  final GeoPoint? destinationLocation; // Destination point

  const DistanceBottomSheet({
    Key? key,
    required this.placeDetails,
    required this.startLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      height: 250,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Route Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Display place details
          if (placeDetails != null)
            
            Text(
              'Destination: ${placeDetails['name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16),
            ),

          // Divider
          const Divider(
            thickness: 1,
            color: Colors.grey,
            height: 24,
          ),

          // Get Directions Button
          if (startLocation != null && destinationLocation != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
              onPressed: () {
                if (startLocation != null && destinationLocation != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteScreen(
                        startLocation: startLocation!,
                        destinationLocation: destinationLocation!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select both start and destination locations.'),
                    ),
                  );
                }
              },
            ),

          // Message if locations are not selected
          if (startLocation == null || destinationLocation == null)
            const Text(
              'Select both start and destination locations to get directions.',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),

          const Spacer(),

          // Close Bottom Sheet Button
          Align(
            alignment: Alignment.center,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 28, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
