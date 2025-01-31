import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat session
  Future<String> createChatSession(String title) async {
    try {
      final docRef = await _firestore.collection('chat_sessions').add({
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'messageCount': 0,
      });
      return docRef.id;
    } catch (e) {
      print('Error creating chat session: $e');
      throw e;
    }
  }

  // Add message to a chat session
  Future<void> addMessage(String sessionId, Map<String, dynamic> message) async {
    try {
      await _firestore
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add({
        ...message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update session's last message
      await _firestore.collection('chat_sessions').doc(sessionId).update({
        'lastMessage': message['text'],
        'messageCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding message: $e');
      throw e;
    }
  }

  // Get all chat sessions
  Stream<QuerySnapshot> getChatSessions() {
    return _firestore
        .collection('chat_sessions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get messages for a specific chat session
  Stream<QuerySnapshot> getMessages(String sessionId) {
    return _firestore
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete a chat session and its messages
  Future<void> deleteChatSession(String sessionId) async {
    try {
      // Delete all messages in the session
      final messages = await _firestore
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      for (var message in messages.docs) {
        batch.delete(message.reference);
      }
      
      // Delete the session document
      batch.delete(_firestore.collection('chat_sessions').doc(sessionId));
      
      await batch.commit();
    } catch (e) {
      print('Error deleting chat session: $e');
      throw e;
    }
  }
}