import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety_app/screens/emergency/emergency_screen.dart';
import 'package:safety_app/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../routes/app_routes.dart';
import 'manage_device_screen.dart';
import 'safety_preferences_screen.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> with SingleTickerProviderStateMixin {
  late AnimationController _profileAnimationController;
  late Animation<double> _profileScaleAnimation;
  late Animation<Offset> _profileSlideAnimation;
  User? currentUser = FirebaseAuth.instance.currentUser;
  String? displayName;
  String? email;
  String? phoneNumber;
  String? profilePicUrl;
  List<Map<String, String>> emergencyContacts = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
     _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _profileScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileAnimationController, 
        curve: Curves.elasticOut,
      ),
    );

    _profileSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), 
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _profileAnimationController, 
        curve: Curves.easeOutBack,
      ),
    );

    _loadUserProfile().then((_) {
      _profileAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _profileAnimationController.forward();
    super.dispose();
  }

  // [Keep all your existing methods unchanged]
  Future<void> _loadUserProfile() async {
    try {
      if (currentUser != null) {
        displayName = currentUser?.displayName ?? "User";
        email = currentUser?.email ?? "No email";
        profilePicUrl = currentUser?.photoURL ?? "";
        await _loadEmergencyContacts();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      var contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('emergency_contacts')
          .get();

      setState(() {
        emergencyContacts = contactsSnapshot.docs.map((doc) {
          return {
            'name': doc['name']?.toString() ?? 'Unknown',
            'phone': doc['phone']?.toString() ?? 'No phone number',
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading emergency contacts: $e");
    }
  }

  Future<void> _addEmergencyContact() async {
    try {
      final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
      final Contact? contact = await contactPicker.selectContact();

      if (contact != null && contact.phoneNumbers!.isNotEmpty) {
        String phone = contact.phoneNumbers!.first.trim() ?? 'No phone';
        String name = contact.fullName ?? 'Unknown';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('emergency_contacts')
            .add({
          'name': name,
          'phone': phone,
        });

        await _loadEmergencyContacts();
      }
    } catch (e) {
      print("Error adding emergency contact: $e");
    }
  }
  Future<void> _makeCall(String phoneNumber) async {
  var status = await Permission.phone.status;
  if (status.isDenied) {
    status = await Permission.phone.request();
  }

  if (status.isGranted) {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print('Could not launch $phoneNumber: $e');
      throw 'Could not launch $phoneNumber';
    }
  } else {
    throw 'Phone call permission denied';
  }
}

  Future<void> _deleteEmergencyContact(Map<String, String> contact) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('emergency_contacts')
          .where('phone', isEqualTo: contact['phone'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }

      await _loadEmergencyContacts();
    } catch (e) {
      print("Error deleting emergency contact: $e");
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ).animate().shimmer(),
            )
          : SlideTransition(
              position: _profileSlideAnimation,
              child: ScaleTransition(
                scale: _profileScaleAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAnimatedProfileHeader(),
                    SliverToBoxAdapter(
                      child: AnimationLimiter(
                        child: Column(
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 500),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              _buildUserStats(),
                              _buildSettingsSection(),
                              _buildSignOutButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnimatedProfileHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    const Color(0xFF3EAAA5),
                  ],
                ),
              ),
            ).animate()
            .slideX(
              begin: -1, 
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutQuad,
            )
            .fadeIn(),

            // Frosted Glass Effect with Enhanced Animation
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 800)),

            // Profile Content with Sophisticated Animations
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: profilePicUrl != null && profilePicUrl!.isNotEmpty
                            ? NetworkImage(profilePicUrl!)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                    ),
                  ).animate()
                  .scale(
                    begin:Offset(0, 0.5), 
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),

                  const SizedBox(height: 16),
                  Text(
                    displayName ?? "User",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ).animate().fade(
                    duration: const Duration(milliseconds: 600),
                  ).slideY(
                    begin: 0.5,
                    duration: const Duration(milliseconds: 600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.people_outline,
            title: "Emergency\nContacts",
            value: "${emergencyContacts.length}",
            color: Color(0xFF3EAAA5),
            onTap: () => _showEmergencyContactsDialog(context),
          ),
          SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.shield_outlined,
            title: "Safety\nTips",
            value: "Stay safe",
            color: Color(0xFF4CAF50),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.safetyTips);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.emergency_outlined,
            title: "Emergency Support",
            subtitle: "Access emergency features",
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergencyScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: "Safety Preferences",
            subtitle: "Customize your safety settings",
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SafetyPreferencesScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.watch_outlined,
            title: "Device Management",
            subtitle: "Manage your wearable device",
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageWearableScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextButton(
        onPressed: () => _showSignOutDialog(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyContactsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildBottomSheetHandle(),
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    color: primaryColor,
                    onPressed: () {
                      Navigator.pop(context);
                      _addEmergencyContact();
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: emergencyContacts.isEmpty
                  ? _buildEmptyContactsState()
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: emergencyContacts.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final contact = emergencyContacts[index];
                        return _buildContactListTile(contact, contact['phone'] ?? '');
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildEmptyContactsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No emergency contacts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add contacts using the + button above',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactListTile(Map<String, String> contact,String phoneNumbers) {
    return Dismissible(
      key: Key(contact['phone'] ?? ''),
      background: Container(
        color: Colors.red[50],
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteEmergencyContact(contact),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            contact['name']?[0].toUpperCase() ?? '?',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          contact['phone'] ?? '',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone_outlined),
          color: Colors.green,
          onPressed: () {
            if (phoneNumbers?.isNotEmpty ?? false) {
            _makeCall(phoneNumbers.split(',')[0]);
          }
          },
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Sign Out",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to sign out?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              "Sign Out",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}