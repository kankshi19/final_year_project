import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safety_app/screens/home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 

class LoginSignupScreen extends StatefulWidget {
  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  int _currentScreen = 0; // 0 = Login, 1 = Sign-Up, 2 = homescreen
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  void _navigateTo(int screenIndex) {
    setState(() {
      _currentScreen = screenIndex;
    });
  }

  // Firebase Authentication Methods
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

  // Future<User?> _signInWithFacebook() async {
  //   final LoginResult result = await FacebookAuth.i.login();

  //   if (result.status == LoginStatus.success) {
  //     final accessToken = result.accessToken;

  //     if (accessToken != null) {
  //       final OAuthCredential facebookCredential = FacebookAuthProvider.credential(accessToken.token);
  //       UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(facebookCredential);
  //       return userCredential.user;
  //     } else {
  //       print("Facebook AccessToken is null");
  //       return null;
  //     }
  //   } else {
  //     print("Facebook login failed: ${result.status}");
  //     return null;
  //   }
  // }

  // Future<User?> _signInWithApple() async {
  //   final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
  //     scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
  //   );

  //   final AuthCredential appleCredential = OAuthProvider("apple.com").credential(
  //     idToken: credential.identityToken,
  //     accessToken: credential.authorizationCode,
  //   );

  //   UserCredential userCredential = await _auth.signInWithCredential(appleCredential);
  //   return userCredential.user;
  // }

  // Sign-Up Methods
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
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User signed up successfully!")));
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

 void _signInWithGoogle() async {
  try {
    User? user = await loginWithGoogle();
    if (user != null) {
      // Check if the user exists in Firestore before adding
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Sign in UnSucessful"),
          content: Text("You have not signed up with Google before "),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      }
      else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User signed in successfully!")));
      // Navigate to home screen after user data is saved
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    }
  } catch (e) {
    print('Error during Google SignUp: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign in failed. Please try again.')));
  }
}



  // void _signUpWithFacebook() async {
  //   User? user = await _signInWithFacebook();
  //   if (user != null) {
  //     FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'name': user.displayName,
  //       'email': user.email,
  //       'photoUrl': user.photoURL,
  //       'phoneNumber': user.phoneNumber,
  //     });
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => HomeScreen()),
  //     );
  //   }
  // }

  // void _signUpWithApple() async {
  //   User? user = await _signInWithApple();
  //   if (user != null) {
  //     FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'name': user.displayName,
  //       'email': user.email,
  //       'photoUrl': user.photoURL,
  //       'phoneNumber': user.phoneNumber,
  //     });
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => HomeScreen()),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentScreen > 0) {
          _navigateTo(_currentScreen - 1); // Navigate back to the previous screen
          return false;
        }
        return true; // Exit the app if on the login screen
      },
      child: Scaffold(
      body: _currentScreen == 0
          ? _buildLoginScreen()
          : _currentScreen == 1
              ? _buildSignupScreen()
              : HomeScreen(),
      )
    );
  }

  Widget _buildLoginScreen() {
    
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _isPasswordVisible = false;  // Boolean to track password visibility

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
        // UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        //   email: email,
        //   password: password,
        // );

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


    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Image.asset('assets/logo.jpg', height: 150), 
          SizedBox(height: 20),
          Text("Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;  // Toggle password visibility
                      });
                    },
                    child: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,  // Change the eye icon
                      color: Colors.blue, // Set your preferred color for the icon
                    ),
                  );
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),  // Add rounded corners
              ),
              hintText: "Password", // Add a hint for better user experience
              
            ),
            obscureText: !_isPasswordVisible,
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
            onPressed: _signInWithGoogle,
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
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? "),
              GestureDetector(
                onTap: () => _navigateTo(1), // Navigate to Sign-Up
                child: Text('Sign up here', style: TextStyle(color: Colors.pink)),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSignupScreen() {
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

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
        _navigateTo(2); // Navigate to homescreen screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User with this phone number already exists")));
      }
    } catch (e) {
      print('Error during normal signup: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed. Please try again.')));
    }
  }


    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Image.asset('assets/logo.jpg', height: 150), // Replace with your logo
          SizedBox(height: 20),
          Text("Sign Up", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Full Name",
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _signUp();
            },
            child: Text("Sign Up"),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
          ),
          SizedBox(height: 20),
          // Google, Facebook, and Apple Sign Up Buttons
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
            icon: FaIcon(FontAwesomeIcons.google, color: const Color.fromARGB(255, 255, 255, 255)), // Google icon
            label: Text(
              'Sign Up with Google',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? "),
              GestureDetector(
                onTap: () => _navigateTo(0), // Navigate to Login
                child: Text('Log in here', style: TextStyle(color: Colors.pink)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // // OTP Verification Screen
  // Widget _buildOTPScreen() {
  //   final _otpControllers = List<TextEditingController>.generate(
  //     4,
  //     (index) => TextEditingController(),
  //   );

  //   final _otpFocusNodes = List<FocusNode>.generate(4, (index) => FocusNode());

  //   return Padding(
  //     padding: const EdgeInsets.all(20.0),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         Text("Verify OTP", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  //         SizedBox(height: 20),
  //         Text("Enter the 4-digit OTP sent to your registered mobile number.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
  //         SizedBox(height: 20),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: List.generate(
  //             4,
  //             (index) => SizedBox(
  //               width: 50,
  //               child: TextField(
  //                 controller: _otpControllers[index],
  //                 focusNode: _otpFocusNodes[index],
  //                 keyboardType: TextInputType.number,
  //                 maxLength: 1,
  //                 textAlign: TextAlign.center,
  //                 decoration: InputDecoration(counterText: '', border: OutlineInputBorder()),
  //                 onChanged: (value) {
  //                   if (value.isNotEmpty) {
  //                     _otpControllers[index].text = value;
  //                     _otpControllers[index].selection = TextSelection.collapsed(offset: value.length);

  //                     if (index < _otpFocusNodes.length - 1) {
  //                       FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
  //                     } else {
  //                       FocusScope.of(context).unfocus(); // Close keyboard
  //                     }
  //                   } else if (value.isEmpty && index > 0) {
  //                     FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
  //                   }
  //                 },
  //               ),
  //             ),
  //           ),
  //         ),
  //         SizedBox(height: 20),
  //         ElevatedButton(
  //           onPressed: () {
  //             String enteredOtp = _otpControllers.map((controller) => controller.text).join();
  //             _verifyOTP(enteredOtp);
  //           },
  //           style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
  //           child: Text("Verify"),
  //         ),
  //         SizedBox(height: 10),
  //         TextButton(
  //           onPressed: () {
  //             _resendOTP();
  //           },
  //           child: Text("Didn't receive the code? Resend"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

//   // OTP Verification Logic
//   void _sendOtp(String phoneNumber) async {
//   _phoneNumber = phoneNumber; // Store the phone number for later use in re-sending OTP
//   await _auth.verifyPhoneNumber(
//     phoneNumber: "+91$phoneNumber",
//     verificationCompleted: (PhoneAuthCredential credential) async {
//       await _auth.signInWithCredential(credential);
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
//     },
//     verificationFailed: (FirebaseAuthException e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification failed: ${e.message}")));
//     },
//     codeSent: (String verificationId, int? resendToken) {
//       setState(() {
//         _verificationId = verificationId;
//         _navigateTo(2); // Navigate to OTP screen
//       });
//     },
//     codeAutoRetrievalTimeout: (String verificationId) {
//       _verificationId = verificationId;
//     },
//   );
// }

//   void _verifyOTP(String otp) async {
//   if (_verificationId != null && otp.length == 4) {
//     try {
//       // Create PhoneAuthCredential using the verification ID and OTP
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );

//       // Sign in with the credential
//       await _auth.signInWithCredential(credential);

//       // Navigate to the home screen on success
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("Error"),
//           content: Text("Invalid OTP. Please try again."),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("OK"),
//             ),
//           ],
//         ),
//       );
//     }
//   } else {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Error"),
//         content: Text("Enter a valid 4-digit OTP."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
// }


//   void _resendOTP() async {
//   await _auth.verifyPhoneNumber(
//     phoneNumber: _phoneNumber, // Make sure to store the entered phone number
//     verificationCompleted: (PhoneAuthCredential credential) async {
//       await _auth.signInWithCredential(credential);
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//       );
//     },
//     verificationFailed: (FirebaseAuthException e) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("Error"),
//           content: Text("Failed to resend OTP. ${e.message}"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("OK"),
//             ),
//           ],
//         ),
//       );
//     },
//     codeSent: (String verificationId, int? resendToken) {
//       setState(() {
//         _verificationId = verificationId;
//       });
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("OTP Resent"),
//           content: Text("A new OTP has been sent to your registered mobile number."),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("OK"),
//             ),
//           ],
//         ),
//       );
//     },
//     codeAutoRetrievalTimeout: (String verificationId) {
//       _verificationId = verificationId;
//     },
//   );
// }
}
