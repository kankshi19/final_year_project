import 'package:flutter/material.dart';
import 'onboarding_screen.dart'; // Import the OnboardingScreen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 70),
            Image.asset(
              'assets/logo.jpg', 
              height: 200,
            ),
            SizedBox(height: 70),
            Text(
              'NirBhaya',
              style: TextStyle(
                color: const Color.fromARGB(255, 133, 14, 56),
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text(
              'A Women Safety App',
              style: TextStyle(
                color: const Color.fromARGB(179, 175, 31, 81),
                fontSize: 20,
              ),
            ),
            SizedBox(height: 70),
            // Loading bar (linear progress indicator)
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: const Color.fromARGB(255, 197, 137, 165),
                color: Color.fromARGB(255, 105, 12, 45), // Light maroon color
              ),
            ),
            SizedBox(height: 250),
            // Footer text
            Text(
              "© 2025 NirBhaya",
              style: TextStyle(
                fontSize: 11,
                color: const Color.fromARGB(255, 95, 12, 40),
              ),
            )
          ],
        ),
      ),
    );
  }
}
