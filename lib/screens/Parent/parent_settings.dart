import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/screens/Parent/community_guidelines_screen.dart';
import 'package:safety_app/utils/shared_prefs_helper.dart';
import 'link_child_screen.dart';
import 'parent_home_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class ParentSettingsScreen extends StatefulWidget {
  @override
  _ParentSettingsScreenState createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isDarkMode = false;
  List<Map<String, dynamic>> _linkedChildren = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final Color primaryTeal = const Color(0xFF3EAAA5);
  final Color primaryPink = const Color(0xFFBC4781);
  final Color lightTeal = const Color(0xFFE0F4F3);
  final Color lightPink = const Color(0xFFFFE4EE);
  final Color darkTeal = const Color(0xFF2C7A76);
  final Color accentYellow = const Color(0xFFFFC107);

  // Animation configurations
  final Duration _animationDuration = const Duration(milliseconds: 800);
  final Curve _animationCurve = Curves.easeInOutCubic;

  

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchUserData();
    _fetchLinkedChildren();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }


  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _animationCurve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: _animationCurve,
    ));

    // Start the animation
    _animationController.forward();
  }


  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? '';
          _phoneController.text = userDoc['phoneNumber'] ?? '';
          _emailController.text = userDoc['email'] ?? '';
        });
      }
    }
  }

  // Future<void> _updateUserData() async {
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       await FirebaseFirestore.instance.collection('parents').doc(user.uid).update({
  //         'name': _nameController.text,
  //         'phoneNumber': _phoneController.text,
  //       });
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Account updated successfully!'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error updating account: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> _fetchLinkedChildren() async {
    String parentId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('parent_child_links')
        .where('parentId', isEqualTo: parentId)
        .get();

    List<Map<String, dynamic>> tempList = [];

    for (var doc in querySnapshot.docs) {
      String childId = doc['childId'];
      String childPhone = doc['childPhone'];

      DocumentSnapshot childSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(childId)
          .get();

      String childName = 'Unknown';

      if (childSnapshot.exists) {
        Map<String, dynamic>? childData = childSnapshot.data() as Map<String, dynamic>?;
        if (childData != null && childData.containsKey('name')) {
          childName = childData['name'];
        }
      }

      tempList.add({'childId': childId, 'childName': childName, 'childPhone': childPhone});
    }

    setState(() {
      _linkedChildren = tempList;
    });
  }

  Future<void> _unlinkChild(String childId) async {
    String parentId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot linkQuery = await FirebaseFirestore.instance
        .collection('parent_child_links')
        .where('parentId', isEqualTo: parentId)
        .where('childId', isEqualTo: childId)
        .get();

    for (var doc in linkQuery.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Child unlinked successfully!')));
    _fetchLinkedChildren();
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dark Mode ${value ? 'Enabled' : 'Disabled'}')),
    );
  }

  Future<void> _navigateToHomeScreen(String childId, String childName) async {
    await SharedPrefsHelper.saveSelectedChild(childId,childName); // Save the selected child
    print("Child ID Saved: $childId");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ParentHomeScreen(
          childId: childId,
          childName: childName,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not launch $number"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildSectionHeader(String title, IconData icon) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.2),
                          blurRadius: 10 * value,
                          spreadRadius: 2 * value,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: primaryTeal),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactTile(String name, String number, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: primaryTeal),
      title: Text(name),
      subtitle: Text("Call: $number"),
      trailing: IconButton(
        icon: Icon(Icons.call, color: primaryPink),
        onPressed: () => _makePhoneCall(number),
      ),
    );
  }


  Widget _buildChildCard(Map<String, dynamic> child, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lightTeal, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Hero(
            tag: 'child_avatar_${child['childId']}',
            child: CircleAvatar(
              backgroundColor: primaryPink,
              child: Text(
                child['childName'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          title: Text(
            child['childName'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkTeal,
            ),
          ),
          subtitle: Text(
            child['childPhone'],
            style: TextStyle(color: primaryTeal),
          ),
          onTap: () => _navigateToHomeScreen(child['childId'], child['childName']),
          trailing: IconButton(
            icon: Icon(Icons.link_off, color: primaryPink),
            onPressed: () => _showUnlinkConfirmation(child['childId'], child['childName']),
          ),
        ),
      ),
    );
  }

  Future<Future<Object?>> _showUnlinkConfirmation(String childId, String childName) async {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Unlink Confirmation',
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Unlink $childName?'),
            content: Text('Are you sure you want to unlink $childName? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: primaryTeal)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _unlinkChild(childId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Unlink'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryTeal,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryTeal.withOpacity(0.1), Colors.white],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Account Settings Section
                _buildAnimatedContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Account Settings', Icons.person),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _nameController,
                        label: 'Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        onPressed: _updateUserData,
                        icon: Icons.save,
                        label: 'Update Account',
                        color: primaryPink,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Linked Children Section
                _buildAnimatedContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Linked Children', Icons.family_restroom),
                      const SizedBox(height: 20),
                      if (_linkedChildren.isEmpty)
                        _buildEmptyStateWidget()
                      else
                        ..._linkedChildren.asMap().entries.map(
                              (entry) => _buildChildCard(entry.value, entry.key),
                            ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LinkChildScreen()),
                          );
                        },
                        icon: Icons.link,
                        label: 'Link a New Child',
                        color: primaryTeal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildAnimatedContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Emergency Contacts', Icons.phone),
                      const SizedBox(height: 16),
                      _buildEmergencyContactTile("Police Helpline", "100", Icons.local_police),
                      _buildEmergencyContactTile("Women Helpline", "1091", Icons.support_agent),
                      _buildEmergencyContactTile("Child Helpline", "1098", Icons.child_care),
                      _buildEmergencyContactTile("Domestic Violence Helpline", "181", Icons.report),
                      _buildEmergencyContactTile("Ambulance", "102", Icons.local_hospital),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildAnimatedContainer(
                  child: ListTile(
                    leading: Icon(Icons.rule, color: primaryTeal),
                    title: Text("Community Guidelines"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CommunityGuidelinesScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // App Preferences Section
                _buildAnimatedContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('App Preferences', Icons.settings),
                      const SizedBox(height: 16),
                      _buildAnimatedPreferenceSwitch(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedContainer({required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryTeal.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryTeal),
          prefixIcon: Icon(icon, color: primaryTeal),
          filled: true,
          fillColor: lightTeal,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryTeal),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightPink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: primaryPink),
            const SizedBox(width: 12),
            Text(
              'No children linked yet',
              style: TextStyle(color: primaryPink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPreferenceSwitch() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: lightTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(color: darkTeal, fontWeight: FontWeight.w500),
              ),
              secondary: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                builder: (context, double value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Icon(Icons.dark_mode, color: primaryTeal),
                  );
                },
              ),
              value: _isDarkMode,
              onChanged: (value) {
                _toggleDarkMode(value);
                // Add ripple effect animation
                _animationController.reset();
                _animationController.forward();
              },
              activeColor: primaryPink,
            ),
          ),
        );
      },
    );
  }

  // Add this method to show a success animation
  void _showSuccessAnimation() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success Animation',
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: primaryTeal,
                    size: 64 * value,
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      Navigator.of(context).pop();
    });
  }

  // Override the _updateUserData method to include success animation
  
  Future<void> _updateUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('parents').doc(user.uid).update({
          'name': _nameController.text,
          'phoneNumber': _phoneController.text,
          'email': _emailController.text,
        });
        if (mounted) {
          _showSuccessAnimation();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Account updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error updating account: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Add ripple effect animation for button presses
  Widget _buildRippleEffect(Widget child) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: primaryTeal.withOpacity(0.2),
        highlightColor: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: child,
      ),
    );
  }
}
