import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safety_app/screens/Parent/setup_parent.dart';
import 'package:safety_app/screens/Parent/parent_home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../routes/app_routes.dart';

class ParentSignupScreen extends StatefulWidget {
  @override
  _ParentSignupScreenState createState() => _ParentSignupScreenState();
}

class _ParentSignupScreenState extends State<ParentSignupScreen> {
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  void _signUpWithGoogle() async {
    try {
      User? user = await loginWithGoogle();
      if (user != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'phoneNumber': '', // Initially empty
          });
        }

        final userData = userDoc.data() as Map<String, dynamic>?; // Ensure proper data fetching
        if (userData == null || userData['phoneNumber'] == '') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SetupParentPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ParentHomeScreen()),
          );
        }
      }
    } catch (e) {
      print('Error during Google SignUp: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign up failed. Please try again.')));
    }
  }

  void _signUp() async {
    final String name = _nameController.text.trim();
    final String phoneNumber = _phoneController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (name.isEmpty || phoneNumber.isEmpty || phoneNumber.length != 10 || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please fill all fields correctly")));
      return;
    }

    try {
      // Sign up user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('parents').doc(user.uid).set({
          'name': name,
          'email': email,
          'photoUrl': null,
          'phoneNumber': phoneNumber,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ParentHomeScreen()),
        );
      }
    } catch (e) {
      print('Error during parent signup: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signup failed. Please try again.')));
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
              SizedBox(height: 50),
              Center(child: Image.asset('assets/logo.jpg', height: 150)),
              SizedBox(height: 20),
              Center(
                child: Text("Parent Sign Up",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person, color: Colors.blue),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email, color: Colors.blue),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone, color: Colors.blue),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue),
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
                onPressed: _signUp,
                child: Text("Sign Up"),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _signUpWithGoogle,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  backgroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 50),
                ),
                icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                label: Text('Sign Up with Google', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
