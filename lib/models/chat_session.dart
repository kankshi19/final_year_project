import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String id;
  String title;
  final DateTime timestamp;
  final List<Map<String, dynamic>> messages;
  String lastMessage;
  int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.timestamp,
    this.messages = const [],
    this.lastMessage = '',
    this.messageCount = 0,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      title: data['title'] ?? 'Untitled Chat',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
      messageCount: data['messageCount'] ?? 0,
      messages: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timestamp': timestamp,
      'lastMessage': lastMessage,
      'messageCount': messageCount,
    };
  }
}