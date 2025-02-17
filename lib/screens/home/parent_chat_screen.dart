import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';


class ParentChatScreen extends StatefulWidget {
  @override
  _ParentChatScreenState createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? linkedUserId;
  String? chatId;

  @override
  void initState() {
    super.initState();
    _fetchLinkedUser();
  }

  Future<void> _fetchLinkedUser() async {
    String currentUserId = _auth.currentUser!.uid;

    var linkSnapshot = await FirebaseFirestore.instance
        .collection('parent_child_links')
        .where(Filter.or(
          Filter("parentId", isEqualTo: currentUserId),
          Filter("childId", isEqualTo: currentUserId),
        ))
        .limit(1)
        .get();

    if (linkSnapshot.docs.isNotEmpty) {
      var linkData = linkSnapshot.docs.first.data();
      String otherUserId =
          linkData['parentId'] == currentUserId ? linkData['childId'] : linkData['parentId'];

      setState(() {
        linkedUserId = otherUserId;
        chatId = currentUserId.hashCode < linkedUserId.hashCode
            ? '${currentUserId}_${linkedUserId}'
            : '${linkedUserId}_${currentUserId}';
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty || linkedUserId == null || chatId == null) return;

    String currentUserId = _auth.currentUser!.uid;

    await FirebaseFirestore.instance.collection('chats').doc(chatId)
        .collection('messages').add({
      'sender': currentUserId,
      'text': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (linkedUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chat')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['sender'] == _auth.currentUser!.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isMe 
                              ? [Colors.blue.shade600, Colors.blue.shade800]
                              : [Colors.grey.shade600, Colors.grey.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isMe ? 12 : 2),
                            topRight: Radius.circular(isMe ? 2 : 12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${message['timestamp']?.toDate().toLocal().hour}:${message['timestamp']?.toDate().toLocal().minute}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),

                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ).animate(onPlay: (controller) => controller.repeat())
                   .shake(duration: 500.ms, hz: 2),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
