import 'package:flutter/material.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Please select your role to continue:",
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                
                // User Side
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login-screen'); // Navigate to user login screen
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Continue as User",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),

                // Parent Side
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/parentLogin-screen'); // Navigate to parent login screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Continue as Parent",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                
                SizedBox(height: 40),

                // Sign Up Option
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text("Don't have an account? "),
                //     GestureDetector(
                //       onTap: () => Navigator.pushNamed(context, '/parentSignup-screen'), // Navigate to signup screen
                //       child: Text(
                //         'Sign up here',
                //         style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
