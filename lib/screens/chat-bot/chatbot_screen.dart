import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../services/chatbot_service.dart';
import '../../utils/constants.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SafetyChatbotService _chatbotService = SafetyChatbotService(
    apiKey: 'AIzaSyBeBoskGYkhRKdYklXSvH7w-GgzI7iiSUY',
  );
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  late AnimationController _typingIndicatorController;

  // Enhanced emergency contacts with icons and categories
  final List<Map<String, dynamic>> emergencyContacts = [
    {
      'name': 'Emergency',
      'number': '911',
      'icon': Icons.emergency,
      'color': Colors.red,
    },
    {
      'name': 'Crisis Hotline',
      'number': '988',
      'icon': Icons.support_agent,
      'color': Colors.orange,
    },
    {
      'name': 'Women Helpline',
      'number': '1-800-799-SAFE',
      'icon': Icons.woman,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTextToSpeech();
    _initializeAnimations();
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    _typingIndicatorController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );
      print('Speech recognition available: $available');
    } catch (e) {
      print('Speech initialization error: $e');
    }
  }

  Future<void> _initializeTextToSpeech() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add({
        'sender': 'bot',
        'text': 'Hello! I\'m your safety companion. How can I help you today?',
        'timestamp': DateTime.now(),
        'isAnimated': false,
      });
    });
  }

  Future<void> _startListening() async {
    try {
      if (await _speech.initialize()) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() {
                _messageController.text = result.recognizedWords;
                _isListening = false;
              });
              _sendMessage();
            }
          },
        );
      }
    } catch (e) {
      print('Error starting speech recognition: $e');
      setState(() => _isListening = false);
    }
  }

  Future<void> _speakMessage(String message) async {
    await _flutterTts.speak(message);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    String userMessage = _messageController.text;
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userMessage,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String response = await _chatbotService.sendMessage(userMessage);
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': response,
          'timestamp': DateTime.now(),
          'isAnimated': true,
        });
        _isLoading = false;
      });
      _scrollToBottom();
      // Optionally read out the response
      // await _speakMessage(response);
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'I apologize, but I\'m having trouble responding. If you\'re in immediate danger, please call emergency services.',
          'timestamp': DateTime.now(),
          'isAnimated': true,
        });
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                            speed: Duration(milliseconds: 50),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      Text('About Me'),
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
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
            Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: EdgeInsets.only(bottom: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(
                    _messages[_messages.length - 1 - index],
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
    _typingIndicatorController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}