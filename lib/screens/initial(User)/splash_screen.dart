import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safety_app/screens/initial(User)/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart'; // Import the OnboardingScreen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTimeAndAuthentication();
  }

  Future<void> _checkFirstTimeAndAuthentication() async {
    // Wait for the splash screen duration
    await Future.delayed(Duration(seconds: 4));

    // Check if it's first time
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      // Mark app as no longer first-time
      await prefs.setBool('isFirstTime', false);
      
      // Navigate to OnboardingScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    } else {
      // Check authentication state
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, go to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // No user logged in, go to LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing SplashScreen UI remains the same
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
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text(
              'A Women Safety App',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(height: 70),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: const Color.fromARGB(255, 197, 137, 165),
                color: Color.fromARGB(255, 105, 12, 45),
              ),
            ),
            SizedBox(height: 250),
            Text(
              "© 2025 NirBhaya",
              style: TextStyle(
                fontSize: 11,
              ),
            )
          ],
        ),
      ),
    );
  }
}