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

  final Color themeColor = Color.fromARGB(255, 62, 170, 165);

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

  void _loadMessages() {
    _firestore
        .collection('users')
        .doc(_currentUser?.uid)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages = snapshot.docs;
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage(String message, {File? file}) async {
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

      await _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('messages')
          .add({
        'text': message,
        'sender': _currentUser?.displayName ?? _currentUser?.email ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'base64Image': base64Image,
        'fileName': fileName,
        'fileType': fileType,
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
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
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are required'))
          );
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable location services'))
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      String locationMessage = 'My Location: https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      _sendMessage(locationMessage);
    } catch (e) {
      print('Error sharing location: $e');
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

  Widget _buildMessageContent(String messageText, String? base64Image, String? fileName, String? fileType) {
    if (base64Image != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (messageText.isNotEmpty) Text(messageText),
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
          if (messageText.isNotEmpty) Text(messageText),
          ElevatedButton.icon(
            onPressed: () {}, // You can implement file download or preview here
            icon: Icon(_getFileIcon(fileType)),
            label: Text('$fileType: $fileName'),
            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
          ),
        ],
      );
    }

    final locationLinkRegex = RegExp(r'My Location: (https://www\.google\.com/maps\?q=[-?\d.,]+)');
    final match = locationLinkRegex.firstMatch(messageText);

    if (match != null) {
      final url = match.group(1)!;
      return GestureDetector(
        onTap: () => _launchURL(url),
        child: Text(
          messageText,
          style: TextStyle(
            fontSize: 16.0,
            color: themeColor,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    return Text(messageText, style: TextStyle(fontSize: 16.0));
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Chat'),
        backgroundColor: themeColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final messageText = message['text'] as String;
                final sender = message['sender'] as String;
                final timestamp = message['timestamp'] as Timestamp?;
                final base64Image = message['base64Image'] as String?;
                final fileName = message['fileName'] as String?;
                final fileType = message['fileType'] as String?;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sender, style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4.0),
                      Container(
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMessageContent(messageText, base64Image, fileName, fileType),
                            SizedBox(height: 4.0),
                            Text(
                              timestamp != null
                                  ? DateFormat('hh:mm a').format(timestamp.toDate())
                                  : '',
                              style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: themeColor),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(Icons.attach_file, color: themeColor),
                  onPressed: _pickFile,
                ),
                IconButton(
                  icon: Icon(Icons.location_on, color: themeColor),
                  onPressed: _shareLocation,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: themeColor),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

