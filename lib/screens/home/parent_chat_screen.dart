import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:safety_app/screens/video_call/videocall_screen.dart';


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
    _listenForIncomingCalls();
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

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'sender': currentUserId,
      'text': _messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  void _listenForIncomingCalls() {
    String currentUserId = _auth.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('video_calls')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'incoming')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var callData = snapshot.docs.first.data();
        _showIncomingCallDialog(callData['callerId'], snapshot.docs.first.id);
      }
    });
  }

  void _showIncomingCallDialog(String callerId, String callId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Incoming Video Call"),
        content: Text("You have an incoming video call."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _rejectCall(callId);
            },
            child: Text("Reject"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _acceptCall(callId);
            },
            child: Text("Accept"),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCall(String callId) async {
    await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(callId)
        .update({'status': 'accepted'});

    if (mounted) {
      Navigator.pushNamed(context, '/video_call', arguments: callId);
    }
  }

  Future<void> _rejectCall(String callId) async {
    await FirebaseFirestore.instance
        .collection('video_calls')
        .doc(callId)
        .update({'status': 'rejected'});
  }

  void _initiateVideoCall() async {
    if (linkedUserId == null || chatId == null) return;

    String currentUserId = _auth.currentUser!.uid;

    await FirebaseFirestore.instance.collection('video_calls').add({
      'callerId': currentUserId,
      'receiverId': linkedUserId,
      'status': 'incoming',
      'timestamp': FieldValue.serverTimestamp(),
    });
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
      appBar: AppBar(
        title: Text('Parent Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call, color: Colors.green),
            onPressed: _initiateVideoCall,
          ),
        ],
      ),
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
                          color: isMe ? Colors.blueAccent : Colors.grey,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(color: Colors.white),
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
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
