
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safety_app/screens/home/home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<User?> signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  void _logInWithGoogle() async {
    try {
      User? user = await signUpWithGoogle();
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Sign in Unsuccessful"),
              content: Text("You have not signed up with Google before"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("User signed in successfully!")));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('Error during Google Sign in: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign in failed. Please try again.')));
    }
  }

      void _loginWithEmail() async {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter both email and password")));
        return;
      }

      try {
        // Check if the user exists in Firestore based on email
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (userSnapshot.docs.isEmpty) {
          // If the user doesn't exist
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email not found. Please sign up first.")));
          return;
        } else {
          // If user is found, check if the entered password matches the stored password
          DocumentSnapshot userDoc = userSnapshot.docs.first;
          String storedPassword = userDoc['password'];

          if (storedPassword == password) {
            // If the passwords match, proceed with Firebase Auth sign-in (using email and password)
            // Sign in with Firebase Authentication (assuming Firebase Auth has been set up for email/password)
            UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Logged In Successfully")));

            // Navigate to home screen after successful login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            // If the password doesn't match
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Incorrect password")));
          }
        }
      } catch (e) {
        print('Error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed. Please try again.')));
      }
}


  @override
  Widget build(BuildContext context) {
        return Scaffold(
      body : SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 90),
            Image.asset('assets/logo.jpg', height: 150), 
            SizedBox(height: 20),
            Text("Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
             TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    hintText: 'Enter your email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blueGrey,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(Icons.email, color: Color.fromARGB(255, 31, 166, 187)),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Color.fromARGB(255, 31, 166, 187)),
                      onPressed: () {
                        setState(() {
                          _emailController.clear();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password TextField
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
                    _loginWithEmail();
                },
              child: Text("Login"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
            SizedBox(height: 20,),
            ElevatedButton.icon(
              onPressed: _logInWithGoogle,
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
              icon: FaIcon(FontAwesomeIcons.google, color: const Color.fromARGB(255, 255, 255, 255)), // Google icon
              label: Text(
                'Log In with Google',
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.signup), // Navigate to Sign-Up
                  child: Text('Sign up here', style: TextStyle(color: Colors.pink)),
                ),
              ],
            ),
          ],
        ),
      ),
    )
    );
  }
}