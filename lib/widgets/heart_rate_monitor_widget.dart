// lib/widgets/heart_rate_monitor_widget.dart
import 'package:flutter/material.dart';

class HeartRateMonitorWidget extends StatefulWidget {
  @override
  _HeartRateMonitorWidgetState createState() => _HeartRateMonitorWidgetState();
}

class _HeartRateMonitorWidgetState extends State<HeartRateMonitorWidget> {
  int _heartRate = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Heart Rate',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            Text(
              '$_heartRate BPM',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _getHeartRateColor(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _simulateHeartRateReading,
              child: Text('Measure Heart Rate'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateHeartRateReading() {
    setState(() {
      // Simulate heart rate between 60-100
      _heartRate = 60 + DateTime.now().second;
    });
  }

  Color _getHeartRateColor() {
    if (_heartRate < 60) return Colors.blue;
    if (_heartRate > 100) return Colors.red;
    return Colors.green;
  }
}