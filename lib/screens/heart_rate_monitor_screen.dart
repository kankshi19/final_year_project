import 'package:flutter/material.dart';
import '../widgets/heart_rate_monitor_widget.dart';

class HeartRateMonitorScreen extends StatelessWidget {
  const HeartRateMonitorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heart Rate Monitor')),
      body: const Center(
        child: HeartRateMonitorWidget(),
      ),
    );
  }
}
