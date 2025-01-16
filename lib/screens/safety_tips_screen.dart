import 'package:flutter/material.dart';

class SafetyGuidelinesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safety Guidelines'),
        backgroundColor: Color.fromARGB(255, 58, 156, 183),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image
              Center(
                child: Image.asset(
                  'assets/image.png', // Add an appropriate image asset
                  height: 200,
                ),
              ),
              SizedBox(height: 16),
              // Title
              Text(
                'Safety for Women at University',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 58, 156, 183),
                ),
              ),
              SizedBox(height: 8),
              // Introductory Text
              Text(
                'Ensuring safety for women at university is crucial. Here are some tips to help you keep yourself safe:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 16),
              // Guidelines List
              _buildGuidelineTile(
                icon: Icons.visibility,
                title: 'Be Aware of Your Surroundings',
                description:
                    'Always stay alert and be aware of your surroundings, especially in secluded or poorly lit areas.',
              ),
              _buildGuidelineTile(
                icon: Icons.security,
                title: 'Use Campus Security Services',
                description:
                    'Make use of campus security services such as escort services and emergency call boxes if available.',
              ),
              _buildGuidelineTile(
                icon: Icons.phone_android,
                title: 'Stay Connected',
                description:
                    'Keep your phone charged and share your location with a trusted friend or family member.',
              ),
              _buildGuidelineTile(
                icon: Icons.thumb_up,
                title: 'Trust Your Instincts',
                description:
                    'If you feel uncomfortable, leave the area and seek help immediately.',
              ),
              SizedBox(height: 16),
              // Footer
              Text(
                'Stay safe and remember, help is always available when you need it!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 58, 156, 183)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineTile({required IconData icon, required String title, required String description}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Color.fromARGB(255, 58, 156, 183)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}