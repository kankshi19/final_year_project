import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatelessWidget {
  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Police', 'number': '100'},
    {'name': 'Ambulance', 'number': '102'},
    {'name': 'Fire Department', 'number': '101'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contacts'),
      ),
      body: ListView.builder(
        itemCount: _emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = _emergencyContacts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Icon(Icons.phone, color: Colors.red),
            ),
            title: Text(contact['name']!),
            subtitle: Text(contact['number']!),
            trailing: IconButton(
              icon: Icon(Icons.call, color: Colors.green),
              onPressed: () {
                // Implement call functionality
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement add contact functionality
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
