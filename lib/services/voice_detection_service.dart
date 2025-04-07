import 'package:flutter/material.dart';
import 'package:safety_app/services/sos_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'dart:async';


class BackgroundVoiceDetectionService {
  static final BackgroundVoiceDetectionService _instance = BackgroundVoiceDetectionService._internal();
  
  factory BackgroundVoiceDetectionService() {
    return _instance;
  }
  
  BackgroundVoiceDetectionService._internal();
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final List<String> _sosKeywords = ['help', 'bachao', 'emergency', 'save'];
  
  // Stream controller for SOS trigger events - for compatibility with existing code
  final StreamController<void> _sosTriggerController = StreamController<void>.broadcast();
  Stream<void> get sosTriggerStream => _sosTriggerController.stream;
  
  // Reference to the SOS Manager
  final SOSManager _sosManager = SOSManager();
  
  // Timer for periodic restart to ensure continuous listening
  Timer? _restartTimer;
  
  // Initialize the speech recognition service
  Future<void> initialize() async {
    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    
    if (available) {
      // Start periodic restart timer to ensure service keeps running
      _restartTimer = Timer.periodic(Duration(minutes: 5), (timer) {
        if (!_isListening) {
          startListening();
        }
      });
    }
  }

  // Start listening for voice commands
  void startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      
      if (available) {
        _isListening = true;
        
        _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: "en_US", // Set appropriate locale
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    }
  }

  // Stop listening for voice commands
  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  // Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    if (status == 'notListening') {
      _isListening = false;
      
      // Restart listening after a brief pause if it was stopped unexpectedly
      Future.delayed(const Duration(seconds: 1), () {
        startListening();
      });
    }
  }

  // Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    _isListening = false;
    
    // Restart listening on error after a brief pause
    Future.delayed(const Duration(seconds: 2), () {
      startListening();
    });
  }

  // Process speech recognition results
  void _onSpeechResult(dynamic result) {
    String recognizedWords = result.recognizedWords.toString().toLowerCase();
    
    // Check if any keyword is found in the recognized speech
    for (String keyword in _sosKeywords) {
      if (recognizedWords.contains(keyword)) {
        // Log the detection
        print("🚨 SOS keyword detected: $keyword");
        
        // Emit an event on the stream for backward compatibility
        _sosTriggerController.add(null);
        
        // Get the current context using the navigatorKey from SOS Manager
        final BuildContext? context = _sosManager.navigatorKey.currentContext;
        
        if (context != null) {
          // Start the SOS process using the SOS Manager
          _sosManager.startSOSProcess(context);
          
          // Pause listening briefly after triggering SOS
          stopListening();
          Future.delayed(const Duration(seconds: 5), () {
            startListening();
          });
        } else {
          print("⚠️ No valid context available to show SOS dialog");
        }
        
        break;
      }
    }
  }

  // Add new keywords to the detection list
  void addKeyword(String keyword) {
    String normalizedKeyword = keyword.toLowerCase().trim();
    if (normalizedKeyword.isNotEmpty && !_sosKeywords.contains(normalizedKeyword)) {
      _sosKeywords.add(normalizedKeyword);
    }
  }

  // Remove keywords from the detection list
  void removeKeyword(String keyword) {
    String normalizedKeyword = keyword.toLowerCase().trim();
    _sosKeywords.remove(normalizedKeyword);
  }

  // Get the current list of keywords
  List<String> getKeywords() {
    return List.from(_sosKeywords);
  }

  // Dispose resources when done
  void dispose() {
    _speech.cancel();
    _restartTimer?.cancel();
    _sosTriggerController.close();
  }
}