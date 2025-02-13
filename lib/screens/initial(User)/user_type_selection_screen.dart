import 'package:flutter/material.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 227, 248, 253),
              const Color.fromARGB(255, 245, 229, 236),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 10,),
                    // Decorative Circle with Icon
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3EAAA5),
                            Color(0xFFBC4781),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.jpg',
                            height: 150,
                            width: 150,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),

                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Welcome Text
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: Duration(milliseconds: 800),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: child,
                              );
                            },
                            child: Text(
                              "Welcome!",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Subtitle
                          Text(
                            "Please select your role to continue:",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),

                          // User Button
                          _buildAnimatedButton(
                            context: context,
                            onPressed: () {
                              Navigator.pushNamed(context, '/login-screen');
                            },
                            text: "Continue as User",
                            icon: Icons.person_outline,
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 62, 170, 165),
                                const Color.fromARGB(255, 53, 205, 195),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Parent Button
                          _buildAnimatedButton(
                            context: context,
                            onPressed: () {
                              Navigator.pushNamed(context, '/parentLogin-screen');
                            },
                            text: "Continue as Parent",
                            icon: Icons.family_restroom,
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 207, 102, 132),
                                const Color.fromARGB(255, 170, 36, 105),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Terms Text
                    Text(
                      "By continuing, you agree to our Terms of Service\nand Privacy Policy",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}