import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ListTile(
            leading: Icon(Icons.call, color: Colors.orange),
            title: Text('Police'),
            subtitle: Text('0-1-5'),
          ),
          ListTile(
            leading: Icon(Icons.local_hospital, color: Colors.redAccent),
            title: Text('Ambulance'),
            subtitle: Text('1-1-2-2'),
          ),
        ],
      ),
    );
  }
}
