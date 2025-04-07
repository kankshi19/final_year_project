import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildChatScreen extends StatefulWidget {
  final String childId;
  final String childName;
   final String parentId;

  ChildChatScreen({
    required this.childId, 
    required this.childName, 
    required this.parentId
  });

  @override
  _ChildChatScreenState createState() => _ChildChatScreenState();
}

class _ChildChatScreenState extends State<ChildChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  String? chatId;

  final Color primaryColor = Color(0xFF3EAAA5); // Teal
  final Color secondaryColor = Color(0xFFBC4781); // Pink
  final Color backgroundColor = Color(0xFFF5F7FB); // Light blue-grey
  final Color messageBubbleColor = Color(0xFF3EAAA5); // Teal
  final Color otherMessageBubbleColor = Color(0xFFE8ECF3); // Light grey

  @override
  void initState() {
    super.initState();
    _createChatId();
  }

  void _createChatId() {
    // Consistent chat ID generation using child and parent IDs
    List<String> sortedIds = [widget.childId, widget.parentId]..sort();
    chatId = '${sortedIds[0]}_${sortedIds[1]}';
    print("✅ Child-Parent Chat ID: $chatId");
  }

void _sendMessage() async {
    if (_messageController.text.isEmpty || chatId == null) return;

    String currentUserId = _auth.currentUser!.uid;
    print("📩 Sending Message - Sender: $currentUserId, Receiver (Child): ${widget.childId}");


    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,   // The Parent sends the message
      'receiverId': widget.childId, // Child is the receiver
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showVideoCallPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Feature Coming Soon!"),
        content: Text("The video call feature will be implemented in a future update."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDateDivider(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(70.0),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Text(
                widget.childName[0].toUpperCase(),
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.childName.split(' ')[0],
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.video_call, color: primaryColor),
            ),
            onPressed: _showVideoCallPopup, // Popup instead of video call
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDateDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Today',
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId) // ✅ Ensure correct chat ID
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("⚠️ No messages found for chatId: $chatId");
          return Center(child: Text("No messages found."));
        }

        var messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            var messageData = message.data() as Map<String, dynamic>?;

            // 🛑 Fix: Ensure messageData is valid
            if (messageData == null ||
                !messageData.containsKey('senderId') ||
                !messageData.containsKey('receiverId') ||
                !messageData.containsKey('text')) {
              print("⚠️ Skipping message due to missing fields: ${message.id}");
              return SizedBox.shrink(); // Skip incomplete messages
            }

            String senderId = messageData['senderId'];
            String receiverId = messageData['receiverId'];
            String messageText = messageData['text'];
            Timestamp? timestamp = messageData['timestamp'];

            bool isMe = senderId == _auth.currentUser!.uid;
            

            // 🛑 Debugging: Check if the child is receiving messages correctly
            print("📩 Message ID: ${message.id}, Sender: $senderId, Receiver: $receiverId, Text: $messageText");
            

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe ? Colors.teal : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messageText,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 4),
                    Text(
                      timestamp != null
                          ? DateFormat('HH:mm').format(timestamp.toDate())
                          : 'Unknown Time',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -4),
            blurRadius: 24,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final Color primaryColor;
  final Color backgroundColor;

  MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? primaryColor : backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 4),
                  blurRadius: 16,
                  color: Colors.black.withOpacity(0.04),
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
