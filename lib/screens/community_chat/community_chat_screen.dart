import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

import '../../utils/constants.dart';

class CommunityChatScreen extends StatefulWidget {
  @override
  _CommunityChatScreenState createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  User? _currentUser;
  List<QueryDocumentSnapshot> _messages = [];
  bool _isEmergencyMode = false;

  final Color themeColor = Color.fromARGB(255, 62, 170, 165);
  final Color secondaryColor = Color.fromARGB(255, 41, 135, 131); // Darker variant
  final Color lightThemeColor = Color.fromARGB(255, 233, 247, 246); // Light variant
  final Color backgroundColor = Color.fromARGB(255, 246, 251, 251); // Very light background
  final Color emergencyColor = Color.fromARGB(255, 211, 47, 47); // Less aggressive red
  final Color safeColor = Color.fromARGB(255, 56, 142, 60);
  

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadMessages();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
  }
  StreamSubscription? _messagesSubscription;

  void _loadMessages() {
    _messagesSubscription?.cancel(); 
     _messagesSubscription =
    _firestore
        .collection('users')
        .doc(_currentUser?.uid)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
      setState(() {
        _messages = snapshot.docs;
      });
      _scrollToBottom();
    });
  }


  String _getFileType(File file) {
    String extension = path.extension(file.path).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif'].contains(extension)) {
      return 'image';
    } else if (['.mp4', '.mov', '.avi'].contains(extension)) {
      return 'video';
    } else if (['.mp3', '.wav', '.aac'].contains(extension)) {
      return 'audio';
    } else {
      return 'file';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _shareLocation() async {
    if (!mounted) return;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are required'))
          );
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable location services'))
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (!mounted) return;

      String locationMessage = 'My Location: https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      _sendMessage(locationMessage);
    } catch (e) {
      print('Error sharing location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location'))
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        await _sendMessage('', file: file);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image. Please check app permissions.'))
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        await _sendMessage('', file: file);
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file. Please check app permissions.'))
      );
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url'))
      );
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildMessageContent(
    String messageText,
    String? base64Image,
    String? fileName,
    String? fileType, {
    bool isEmergency = false,
  }) {
    if (base64Image != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (messageText.isNotEmpty)
            Text(
              messageText,
              style: TextStyle(
                color: isEmergency ? emergencyColor : Colors.black,
                fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(base64Image),
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    } else if (fileName != null && fileType != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (messageText.isNotEmpty)
            Text(
              messageText,
              style: TextStyle(
                color: isEmergency ? emergencyColor : Colors.black,
                fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ElevatedButton.icon(
            onPressed: () {}, // Implement file download or preview
            icon: Icon(_getFileIcon(fileType)),
            label: Text('$fileType: $fileName'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEmergency ? emergencyColor : primaryColor,
            ),
          ),
        ],
      );
    }

    final locationLinkRegex =
        RegExp(r'My Location: (https://www\.google\.com/maps\?q=[-?\d.,]+)');
    final match = locationLinkRegex.firstMatch(messageText);

    if (match != null) {
      final url = match.group(1)!;
      return GestureDetector(
        onTap: () => _launchURL(url),
        child: Text(
          messageText,
          style: TextStyle(
            fontSize: 16.0,
            color: isEmergency ? emergencyColor : primaryColor,
            decoration: TextDecoration.underline,
            fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return Text(
      messageText,
      style: TextStyle(
        fontSize: 16.0,
        color: isEmergency ? emergencyColor : Colors.black,
        fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot message, bool isCurrentUser) {
    final messageText = message['text'] as String??'';
    final sender = message['sender'] as String??'Anonymous';
    final timestamp = message['timestamp'] as Timestamp?;
    final base64Image = message['base64Image'] as String?;
    final fileName = message['fileName'] as String?;
    final fileType = message['fileType'] as String?;
     // Add null checks and default values for isEmergency and isSafeStatus
  final isEmergency = message.data().toString().contains('isEmergency') 
      ? message['isEmergency'] as bool? ?? false 
      : false;
  final isSafeStatus = message.data().toString().contains('isSafeStatus') 
      ? message['isSafeStatus'] as bool? ?? false 
      : false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser)
                CircleAvatar(
                  backgroundColor: themeColor.withOpacity(0.8),
                  child: Text(
                    sender.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                  radius: 16,
                ),
              SizedBox(width: 8),
              Text(
                sender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isEmergency
                  ? emergencyColor.withOpacity(0.08)
                  : isSafeStatus
                      ? safeColor.withOpacity(0.08)
                      : isCurrentUser
                          ? themeColor.withOpacity(0.1)
                          : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: isEmergency
                  ? Border.all(color: emergencyColor.withOpacity(0.5), width: 1)
                  : isSafeStatus
                      ? Border.all(color: safeColor.withOpacity(0.5), width: 1)
                      : Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEmergency)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: emergencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: emergencyColor, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Emergency Alert',
                          style: TextStyle(
                            color: emergencyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isSafeStatus)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: safeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: safeColor, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Safety Update',
                          style: TextStyle(
                            color: safeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildMessageContent(
                  messageText,
                  base64Image,
                  fileName,
                  fileType,
                  isEmergency: isEmergency,
                ),
                SizedBox(height: 4.0),
                Text(
                  timestamp != null
                      ? DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())
                      : '',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.emergency,
            label: 'Emergency',
            color: emergencyColor,
            onPressed: _toggleEmergencyMode,
          ),
          _buildToolbarButton(
            icon: Icons.check_circle_outline,
            label: 'I\'m Safe',
            color: safeColor,
            onPressed: _sendSafeStatus,
          ),
          _buildToolbarButton(
            icon: Icons.location_on_outlined,
            label: 'Location',
            color: themeColor,
            onPressed: _shareLocation,
          ),
          _buildToolbarButton(
            icon: Icons.phone_outlined,
            label: 'Helpline',
            color: secondaryColor,
            onPressed: () => _launchURL('tel:1091'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Support',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Safe Space for Women',
              style: TextStyle(
                color: themeColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: themeColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Community Guidelines',
                    style: TextStyle(color: themeColor),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGuidelineItem(
                          Icons.group_outlined,
                          'This is a safe space for women to support each other',
                        ),
                        _buildGuidelineItem(
                          Icons.favorite_outline,
                          'Be respectful and kind',
                        ),
                        _buildGuidelineItem(
                          Icons.warning_outlined,
                          'Report any inappropriate behavior',
                        ),
                        _buildGuidelineItem(
                          Icons.emergency_outlined,
                          'Use emergency mode only for genuine emergencies',
                        ),
                        _buildGuidelineItem(
                          Icons.location_on_outlined,
                          'Share location only when necessary',
                        ),
                        _buildGuidelineItem(
                          Icons.healing_outlined,
                          'Support others in need',
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Close', style: TextStyle(color: themeColor)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildSafetyToolbar(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  // controller: _scrollController,
                  reverse: true,
                  itemCount: _messages.length,
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isCurrentUser =
                        message['sender'] == _currentUser?.displayName ||
                            message['sender'] == _currentUser?.email;
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined,
                        color: themeColor.withOpacity(0.8)),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file_outlined,
                        color: themeColor.withOpacity(0.8)),
                    onPressed: _pickFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isEmergencyMode
                            ? 'Send emergency message...'
                            : 'Type a message...',
                        hintStyle: TextStyle(
                          color: _isEmergencyMode
                              ? emergencyColor.withOpacity(0.6)
                              : Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: lightThemeColor,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        prefixIcon: _isEmergencyMode
                            ? Icon(Icons.warning_amber_rounded,
                                color: emergencyColor)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isEmergencyMode ? emergencyColor : themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(
                        _messageController.text,
                        isEmergency: _isEmergencyMode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: themeColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEmergencyMode() {
    setState(() {
      _isEmergencyMode = !_isEmergencyMode;
    });
    if (_isEmergencyMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency Mode Activated'),
          backgroundColor: emergencyColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _sendSafeStatus() async {
    await _sendMessage(
      "I'm safe and doing well! 💚",
      isEmergency: false,
      isSafeStatus: true,
    );
  }

  Future<void> _sendMessage(
    String message, {
    File? file,
    bool isEmergency = false,
    bool isSafeStatus = false,
  }) async {
    if (message.trim().isEmpty && file == null) return;

    try {
      String? base64Image;
      String? fileName;
      String? fileType;

      if (file != null) {
        fileName = path.basename(file.path);
        fileType = _getFileType(file);
        if (fileType == 'image') {
          List<int> imageBytes = await file.readAsBytes();
          base64Image = base64Encode(imageBytes);
        }
      }
      final messageData = {
      'text': message,
      'sender': _currentUser?.displayName ?? _currentUser?.email ?? 'Anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'base64Image': base64Image,
      'fileName': fileName,
      'fileType': fileType,
      'isEmergency': isEmergency || _isEmergencyMode,
      'isSafeStatus': isSafeStatus,
    };

      await _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('messages')
          .add(messageData);

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
  }
 

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

