import 'package:flutter/material.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE5E5), Color(0xFFE5F1FF)], // Soft pink to soft blue
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B8CDE), // Soft indigo
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.grey.withOpacity(0.3),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Please select your role to continue:",
                    style: TextStyle(fontSize: 18, color: Color(0xFF7B8CDE).withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 60),
                  
                  // User Side
                  _buildRoleButton(
                    context: context,
                    title: "Continue as User",
                    icon: Icons.person,
                    color: Color(0xFFFFC8DD), // Soft pink
                    textColor: Color(0xFF7B8CDE), // Soft indigo
                    onPressed: () => Navigator.pushNamed(context, '/login-screen'),
                  ),
                  SizedBox(height: 20),

                  // Parent Side
                  _buildRoleButton(
                    context: context,
                    title: "Continue as Parent",
                    icon: Icons.family_restroom,
                    color: Color(0xFFBDE0FE), // Soft blue
                    textColor: Color(0xFF7B8CDE), // Soft indigo
                    onPressed: () => Navigator.pushNamed(context, '/parentLogin-screen'),
                  ),
                  
                  SizedBox(height: 60),

                  // // Sign Up Option
                  // Text(
                  //   "Don't have an account?",
                  //   style: TextStyle(color: Color(0xFF7B8CDE).withOpacity(0.8)),
                  // ),
                  // SizedBox(height: 8),
                  // GestureDetector(
                  //   onTap: () => Navigator.pushNamed(context, '/parentSignup-screen'),
                  //   child: Text(
                  //     'Sign up here',
                  //     style: TextStyle(
                  //       color: Color(0xFFA2D2FF), // Soft light blue
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 16,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

