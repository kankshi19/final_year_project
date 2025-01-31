import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import '../../services/chatbot_service.dart';
import '../../services/firebase_services.dart';
import '../../utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/../models/chat_session.dart';
import '/../models/chat_session.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SafetyChatbotService _chatbotService = SafetyChatbotService(
    apiKey: chatbotApiKey,
  );
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<QuerySnapshot>? _chatSessionsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  String? _currentSessionId;
  List<ChatSession> _chatSessions = [];
  List<Map<String, dynamic>> _messages = [];
  late ChatSession _currentSession;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSidebarOpen = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  // Emergency contacts
  final List<Map<String, dynamic>> emergencyContacts = [
    {
      'name': 'Emergency',
      'number': '911',
      'icon': Icons.emergency,
      'color': Colors.red,
    },
    {
      'name': 'Women Helpline',
      'number': '1091',
      'icon': Icons.woman,
      'color': Colors.purple,
    },
    {
      'name': 'Police',
      'number': '100',
      'icon': Icons.local_police,
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNewSession();
    _subscribeToSessions();
    _requestPermissions();
    _initializeTextToSpeech();
  }

  void _subscribeToSessions() {
    _chatSessionsSubscription = _firebaseService.getChatSessions().listen(
      (snapshot) {
        setState(() {
          _chatSessions = snapshot.docs
              .map((doc) => ChatSession.fromFirestore(doc))
              .toList();

          if (_currentSessionId == null && _chatSessions.isNotEmpty) {
            _currentSessionId = _chatSessions.first.id;
            _subscribeToMessages(_currentSessionId!);
          }
        });
      },
      onError: (error) {
        print('Error subscribing to sessions: $error');
        _showErrorSnackBar('Failed to load chat history');
      },
    );
  }

  void _subscribeToMessages(String sessionId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _firebaseService.getMessages(sessionId).listen(
      (snapshot) {
        setState(() {
          _messages = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
            };
          }).toList();
        });
      },
      onError: (error) {
        print('Error subscribing to messages: $error');
        _showErrorSnackBar('Failed to load messages');
      },
    );
  }

  Future<void> _initializeNewSession() async {
    try {
      final sessionId = await _firebaseService.createChatSession(
        'Chat ${DateFormat('MMM d, HH:mm').format(DateTime.now())}',
      );
      setState(() => _currentSessionId = sessionId);
      _subscribeToMessages(sessionId);
      _addWelcomeMessage();
    } catch (e) {
      print('Error creating new session: $e');
      _showErrorSnackBar('Failed to create new chat');
    }
  }


  void _initializeAnimations() {
    _sidebarController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sidebarAnimation = Tween<double>(
      begin: -300.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeTextToSpeech() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
  }

  Future<void> _requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus.isGranted) {
      await _initializeSpeechRecognition();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Microphone Permission Required'),
        content: Text(
          'Voice input requires microphone access. Please enable it in your device settings to use this feature.'
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initializeSpeechRecognition() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          print('Speech error: $error');
          setState(() => _isListening = false);
          _showErrorSnackBar('Speech recognition error occurred');
        },
      );
      print('Speech recognition available: $available');
    } catch (e) {
      print('Speech initialization error: $e');
      _showErrorSnackBar('Failed to initialize speech recognition');
    }
  }

  Future<void> _addWelcomeMessage() async {
    if (_currentSessionId == null) return;

    final welcomeMessage = {
      'sender': 'bot',
      'text': 'Hello! I\'m your safety companion. How can I help you today?',
      'timestamp': DateTime.now(),
      'isAnimated': true,
    };

    try {
      await _firebaseService.addMessage(_currentSessionId!, welcomeMessage);
    } catch (e) {
      print('Error adding welcome message: $e');
      _showErrorSnackBar('Failed to initialize chat');
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  Future<void> _startListening() async {
    if (!await Permission.microphone.isGranted) {
      _showPermissionDeniedDialog();
      return;
    }

    try {
      if (!_isListening) {
        final available = await _speech.initialize();
        if (available) {
          setState(() => _isListening = true);
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _messageController.text = result.recognizedWords;
                if (result.finalResult) {
                  _isListening = false;
                  if (_messageController.text.isNotEmpty) {
                    _sendMessage();
                  }
                }
              });
            },
            listenFor: Duration(seconds: 30),
            pauseFor: Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        }
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } catch (e) {
      print('Error in speech recognition: $e');
      setState(() => _isListening = false);
      _showErrorSnackBar('Failed to start voice input');
    }
  }

  Future<void> _speakMessage(String message) async {
    await _flutterTts.speak(message);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    var status = await Permission.phone.status;
    if (status.isDenied) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      try {
        await launchUrl(launchUri);
      } catch (e) {
        _showErrorSnackBar('Could not make the call');
      }
    } else {
      _showErrorSnackBar('Phone permission denied');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _currentSessionId == null) return;

    final userMessage = _messageController.text;
    final message = {
      'sender': 'user',
      'text': userMessage,
      'timestamp': DateTime.now(),
    };

    _messageController.clear();
    _scrollToBottom();
  
    
    try {
      await _firebaseService.addMessage(_currentSessionId!, message);
      
      setState(() => _isLoading = true);
      
      final response = await _chatbotService.sendMessage(userMessage);
      
      await _firebaseService.addMessage(_currentSessionId!, {
        'sender': 'bot',
        'text': response,
        'timestamp': DateTime.now(),
        'isAnimated': true,
      });
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      print('Error sending message: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to send message');
    }
  }

  void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });
}

  Future<void> _deleteSession(ChatSession session) async {
    try {
      await _firebaseService.deleteChatSession(session.id);
      if (session.id == _currentSessionId) {
        setState(() {
          _currentSessionId = _chatSessions.isNotEmpty ? _chatSessions.first.id : null;
        });
        if (_currentSessionId != null) {
          _subscribeToMessages(_currentSessionId!);
        }
      }
    } catch (e) {
      print('Error deleting session: $e');
      _showErrorSnackBar('Failed to delete chat');
    }
  }

  void _showDeleteConfirmation(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                _chatSessions.remove(session);
                if (session.id == _currentSession.id) {
                  if (_chatSessions.isEmpty) {
                    _initializeNewSession();
                  } else {
                    _currentSession = _chatSessions.last;
                    _messages = _currentSession.messages;
                  }
                }
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsBar() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemCount: emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = emergencyContacts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () => _makeCall(contact['number']),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 120,
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        contact['icon'],
                        color: contact['color'],
                        size: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        contact['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        contact['number'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['sender'] == 'user';
    final bool isAnimated = message['isAnimated'] ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: primaryColor,
              child: Icon(Icons.security, color: Colors.white),
              radius: 16,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isUser 
                  ? primaryColor.withOpacity(0.9)
                  : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAnimated && !isUser)
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            message['text'],
                            speed: Duration(milliseconds: 10),
                          ),
                        ],
                        totalRepeatCount: 1,
                        displayFullTextOnTap: true,
                      ),
                    )
                  else
                    Text(
                      message['text'],
                      style: TextStyle(
                        fontSize: 16,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  if (!isUser)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message['text']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          color: Colors.grey[600],
                        ),
                        IconButton(
                          icon: Icon(Icons.volume_up, size: 16),
                          onPressed: () => _speakMessage(message['text']),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSidebar() {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _initializeNewSession,
                  tooltip: 'New Chat',
                ),
              ],
            ),
          ),
          Expanded(
            child: _chatSessions.isEmpty
                ? Center(
                    child: Text(
                      'No chat history',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatSessions.length,
                    itemBuilder: (context, index) {
                      final session = _chatSessions[index];
                      final isSelected = session.id == _currentSessionId;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: primaryColor.withOpacity(0.1),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isSelected ? primaryColor : Colors.grey,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              DateFormat('MMM d, HH:mm').format(session.timestamp),
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _currentSessionId = session.id;
                            _subscribeToMessages(session.id);
                          });
                          _toggleSidebar();
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline),
                          onPressed: () => _showDeleteConfirmation(session),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu),
          onPressed: _toggleSidebar,
        ),
        title: Text(
          'Safety Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.security, color: primaryColor),
                      SizedBox(width: 8),
                      Text('About Eva'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This AI assistant is here to help you with:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      _buildInfoItem(Icons.security, 'Safety guidance and support'),
                      _buildInfoItem(Icons.emergency, 'Emergency assistance'),
                      _buildInfoItem(Icons.psychology, 'Emotional support'),
                      _buildInfoItem(Icons.help_outline, 'General safety advice'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                _buildEmergencyContactsBar(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.only(bottom: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(
                        _messages[index],
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Thinking...'),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? primaryColor : Colors.grey,
                        ),
                        onPressed: _startListening,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: _sendMessage,
                        child: Icon(Icons.send, color: Colors.white),
                        backgroundColor: primaryColor,
                        mini: true,
                        elevation: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_sidebarAnimation.value, 0),
                child: child,
              );
            },
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    _flutterTts.stop();
    _chatSessionsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}