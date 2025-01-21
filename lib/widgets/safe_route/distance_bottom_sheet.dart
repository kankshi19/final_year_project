import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:safety_app/utils/constants.dart';

import '../../screens/safe-route/route_screen.dart';

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
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      height: 300, // Increased height for better spacing
      padding: const EdgeInsets.all(20.0), // Increased padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Route Details',
            style: TextStyle(
              fontSize: 22, // Increased font size
              fontWeight: FontWeight.bold,
              color: primaryColor, // Changed color for emphasis
            ),
          ),
          const SizedBox(height: 12), // Increased space

          // Display place details
          if (placeDetails != null)
            Text(
              'Destination: ${placeDetails['name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 18), // Increased font size
            ),

          // Divider
          const Divider(
            thickness: 1.5,
            color: Colors.grey,
            height: 30, // Increased height for better spacing
          ),

          // Get Directions Button
          if (startLocation != null && destinationLocation != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Added padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Rounded corners
                elevation: 5, // Added elevation for depth
              ),
              icon: const Icon(Icons.directions_outlined,color: Colors.white,), // Changed icon for clarity
              label: const Text('Get Directions', style: TextStyle(fontSize: 16)), // Increased font size
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
                      content:
                          Text('Please select both start and destination locations.'),
                    ),
                  );
                }
              },
            ),

          // Message if locations are not selected
          if (startLocation == null || destinationLocation == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Select both start and destination locations to get directions.',
                style:
                    TextStyle(fontSize: 14, color: Colors.redAccent), // Changed color for visibility
              ),
            ),

          const Spacer(),

          // Close Bottom Sheet Button
          Align(
            alignment: Alignment.center,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon:
                  const Icon(Icons.close, size: 30, color: Colors.grey), // Increased icon size
            ),
          ),
        ],
      ),
    );
  }
}
