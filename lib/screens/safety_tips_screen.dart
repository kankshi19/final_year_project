// lib/screens/safety_tips_screen.dart
import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  final List<String> _safetyTips = [
    'Always be aware of your surroundings',
    'Trust your instincts',
    'Keep your phone charged',
    'Share your location with trusted contacts',
    'Learn basic self-defense techniques',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safety Tips'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _safetyTips.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(Icons.security, color: Colors.blue),
              title: Text(_safetyTips[index]),
            ),
          );
        },
      ),
    );
  }
}