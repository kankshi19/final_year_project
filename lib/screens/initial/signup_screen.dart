import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safety_app/screens/home/home_screen.dart';
import 'package:safety_app/screens/initial/login_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../routes/app_routes.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<User?> loginWithGoogle() async {
  try {
    // Trigger the Google Sign-In flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // If the user cancels the sign-in, return null
    if (googleUser == null) {
      return null;
    }

    // Get the authentication details from the Google sign-in
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new AuthCredential for Firebase using the Google authentication details
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in with the credential and get the UserCredential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Return the signed-in user
    return userCredential.user;
  } catch (e) {
    // Handle errors (e.g., network issues, sign-in problems)
    print('Error signing in with Google: $e');
    return null;
  }
}


    void _signUpWithGoogle() async {
  try {
    User? user = await loginWithGoogle();
    if (user != null) {
      // Check if the user exists in Firestore before adding
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Adding user details only if user doesn't exist in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'phoneNumber': user.phoneNumber,
        });
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Sign up Sucessful"),
          content: Text("You have signed up successfully "),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User signed up successfully!")));
      // Navigate to home screen after user data is saved
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  } catch (e) {
    print('Error during Google SignUp: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed. Please try again.')));
  }
}


      void _signUp() async {
    final String name = _nameController.text.trim();
    final String phoneNumber = _phoneController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (name.isEmpty || phoneNumber.isEmpty || phoneNumber.length != 10 || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields correctly")));
      return;
    }

    try {
      // Check if the user already exists based on email or phone number
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(phoneNumber).get();

      if (!userDoc.exists) {
        // Add user data to Firestore (using phone number as the document ID)
        await FirebaseFirestore.instance.collection('users').doc(phoneNumber).set({
          'name': name,
          'email': email,
          'photoUrl': null, // No photo URL for normal signup
          'phoneNumber': phoneNumber,
          'password': password,
        });

        showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Sign up Sucessful"),
          content: Text("You have signed up successfully "),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );

        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User signed up successfully!")));
        
        // Navigate to home screen after successful signup
        Navigator.pushNamed(context, AppRoutes.home); // Navigate to homescreen screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User with this phone number already exists")));
      }
    } catch (e) {
      print('Error during normal signup: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed. Please try again.')));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
  body: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50), // Add some space at the top
          Center(
            child: Image.asset('assets/logo.jpg', height: 150),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              "Sign Up",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Full Name",
              prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 31, 166, 187)),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email, color: Color.fromARGB(255, 31, 166, 187)),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              prefixIcon: Icon(Icons.phone, color: Color.fromARGB(255, 31, 166, 187)),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blueGrey,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon:
                        const Icon(Icons.lock, color: Color.fromARGB(255, 31, 166, 187)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: const Color.fromARGB(255, 31, 166, 187),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _signUp();
            },
            child: Text("Sign Up"),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _signUpWithGoogle,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              backgroundColor: const Color.fromARGB(255, 236, 78, 57),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 5,
            ),
            icon: FaIcon(
              FontAwesomeIcons.google,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            label: Text(
              'Sign Up with Google',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? "),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.login), // Navigate to Login
                child: Text(
                  'Log in here',
                  style: TextStyle(color: Colors.pink),
                ),
              ),
            ],
          ),
          SizedBox(height: 20), // Add some space at the bottom
        ],
      ),
    ),
  ),
);
}
}