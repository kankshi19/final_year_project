import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
