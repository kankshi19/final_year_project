// lib/screens/heart_rate_monitor_screen.dart
import 'package:flutter/material.dart';
import 'package:safety_app/widgets/heart_rate_monitor_widget.dart';

class HeartRateMonitorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart Rate Monitor'),
      ),
      body: Center(
        child: HeartRateMonitorWidget(),
      ),
    );
  }
}