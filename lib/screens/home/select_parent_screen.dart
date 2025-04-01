import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'parent_chat_screen.dart';

class SelectParentScreen extends StatefulWidget {

  @override
  _SelectParentScreenState createState() => _SelectParentScreenState();
}

class _SelectParentScreenState extends State<SelectParentScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> linkedParents = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // App color scheme
  final Color primaryColor = Color(0xFF3EAAA5); // Teal
  final Color secondaryColor = Color(0xFFBC4781); // Pink
  final Color backgroundColor = Color(0xFFF5F7FB); // Light blue-grey
  final Color messageBubbleColor = Color(0xFF3EAAA5); // Teal
  final Color otherMessageBubbleColor = Color(0xFFE8ECF3); // Light grey
  
  // Single light pastel color for parent avatars
  final Color avatarColor = Color(0xFFFCCFE8); // Light pastel blue

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
    _fetchLinkedParents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLinkedParents() async {
    setState(() {
      _isLoading = true;
    });

    String currentUserId = _auth.currentUser!.uid;

    try {
      var linkSnapshot = await FirebaseFirestore.instance
          .collection('parent_child_links')
          .where('childId', isEqualTo: currentUserId)
          .get();

      List<String> parentIds = linkSnapshot.docs
          .map((doc) => doc.data()['parentId'].toString())
          .toList();

      if (parentIds.isEmpty) {
        print("No linked parents found.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      var parentSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where(FieldPath.documentId, whereIn: parentIds)
          .get();

      setState(() {
        linkedParents = parentSnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching linked parents: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : linkedParents.isEmpty
                        ? _buildEmptyState()
                        : _buildParentsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 8),
              Text(
                "Family Connection",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            child: Text(
              "Select a parent to chat with",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Connecting with family...",
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration for empty state with a single pastel color
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: otherMessageBubbleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 100,
              color: avatarColor, // Using the single pastel color
            ),
          ),
          SizedBox(height: 32),
          Text(
            "No Parents Connected",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              "When you connect with your parents, they'll appear here for quick access to chat",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: _fetchLinkedParents,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: Text(
              "Refresh",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: linkedParents.length,
        itemBuilder: (context, index) {
          var parent = linkedParents[index];
          // Adding simple animations without the package dependency
          return FadeTransition(
            opacity: Animation<double>.fromValueListenable(
              Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
                ),
              ),
            ),
            child: SlideTransition(
              position: Animation<Offset>.fromValueListenable(
                Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
                  ),
                ),
              ),
              child: _buildParentCard(parent, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> parent, int index) {
    // Generate avatar or use profile pic if available
    Widget avatar;
    if (parent['profilePicUrl'] != null) {
      avatar = CircleAvatar(
        radius: 35,
        backgroundImage: NetworkImage(parent['profilePicUrl']),
      );
    } else {
      // Generate initials for avatar
      String initials = "";
      if (parent['name'] != null && parent['name'].toString().isNotEmpty) {
        List<String> nameParts = parent['name'].toString().split(" ");
        if (nameParts.isNotEmpty) {
          initials += nameParts[0][0];
          if (nameParts.length > 1) {
            initials += nameParts[nameParts.length - 1][0];
          }
        }
      } else {
        initials = "?";
      }
      
      // Use the single pastel color for all avatars
      avatar = Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: avatarColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: avatarColor.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      
      onTap: () {
        String childId = FirebaseAuth.instance.currentUser!.uid;
        print("Navigating to ParentChatScreen with:");
        print("Parent ID: ${parent['id']}");
        print("Parent Name: ${parent['name'] ?? "Unknown"}");
        print("Child ID: $childId");
        // Navigate to chat screen
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ParentChatScreen(
              parentId: parent['id'],
              parentName: parent['name'] ?? "Unknown",
              childId: childId,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              avatar,
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent['name'] ?? "Unknown",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: secondaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          parent['phoneNumber'] ?? "No phone number",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Tap to chat",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}