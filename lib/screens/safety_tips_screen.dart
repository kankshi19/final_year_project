import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Tips')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ListTile(
            title: Text('Tip 1'),
            subtitle: Text('Stay aware of your surroundings.'),
          ),
          ListTile(
            title: Text('Tip 2'),
            subtitle: Text('Share your live location with friends/family.'),
          ),
        ],
      ),
    );
  }
}
