import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Community Guidelines",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF3EAAA5),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3EAAA5).withOpacity(0.3), Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(20.0),
            children: [
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFF3EAAA5).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    size: 40,
                    color: Color(0xFF3EAAA5),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Community Guidelines",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3EAAA5),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              _buildGuidelineCard(
                icon: Icons.location_on,
                title: "Location Safety",
                description: "Ensure your child's safety by checking their location updates regularly.",
                context: context,
              ),
              _buildGuidelineCard(
                icon: Icons.warning,
                title: "Emergency Features",
                description: "Encourage your child to use emergency features responsibly.",
                context: context,
              ),
              _buildGuidelineCard(
                icon: Icons.contact_phone,
                title: "Contact Updates",
                description: "Keep emergency contacts updated to receive instant alerts.",
                context: context,
              ),
              _buildGuidelineCard(
                icon: Icons.privacy_tip,
                title: "Privacy Protection",
                description: "Avoid sharing personal details with strangers.",
                context: context,
              ),
              _buildGuidelineCard(
                icon: Icons.report,
                title: "Report Activity",
                description: "Report suspicious activity to enhance community safety.",
                context: context,
              ),
              _buildGuidelineCard(
                icon: Icons.info,
                title: "Stay Informed",
                description: "Support and stay informed about your child's safety.",
                context: context,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("I Understand"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3EAAA5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineCard({
    required IconData icon,
    required String title,
    required String description,
    required BuildContext context,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF3EAAA5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Color(0xFF3EAAA5),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3EAAA5),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}