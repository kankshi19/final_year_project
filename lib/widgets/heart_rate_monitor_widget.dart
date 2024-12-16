import 'package:flutter/material.dart';

class HeartRateMonitorWidget extends StatelessWidget {
  const HeartRateMonitorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.favorite, color: Colors.red, size: 100),
        SizedBox(height: 16),
        Text(
          'Monitoring Heart Rate...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
