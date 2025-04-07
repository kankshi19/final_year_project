import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'bleService.dart';

class SOSManager {
  // Singleton instance
  static final SOSManager _instance = SOSManager._internal();
  
  factory SOSManager() {
    return _instance;
  }
  
  SOSManager._internal();
  
  // Global navigator key for accessing navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Dependencies
  final BleService _bleService = BleService();
  
  
  // SOS state variables
  bool _isSending = false;
  String _sosStatus = "";
  
  // Public getters for state
  bool get isSending => _isSending;
  String get sosStatus => _sosStatus;
  
  // Stream controller for status updates
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;
  
  // Initialize the SOS Manager
  void initialize() {
    // Check BLE connection
    _checkBleConnection();
  }
  
  // Show SOS countdown dialog
  void startSOSProcess(BuildContext context) {
    // Vibrate phone to give tactile feedback
    HapticFeedback.heavyImpact();
    
    // Start the countdown dialog
    _startCountdown(context);
  }
  
  // Countdown dialog implementation
  int _countdown = 5;
  Timer? _timer;
  BuildContext? _dialogContext;
  
 void _startCountdown(BuildContext context) {
  _countdown = 5;
  _dialogContext = context;

  // Start the countdown timer
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (_countdown > 0) {
      // Update the countdown value and notify the stream
      _statusController.add("Countdown: $_countdown");
      _countdown--;
    } else {
      _triggerSOS();
      timer.cancel();
    }
  });

  // Show the enhanced confirmation dialog
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing by tapping outside
    builder: (context) {
      _dialogContext = context;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              "EMERGENCY SOS",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your emergency contacts will be notified",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 4),
              ),
              child: Center(
                child: StreamBuilder<String>(
                  stream: statusStream,
                  initialData: "Countdown: 5",
                  builder: (context, snapshot) {
                    // Extract number from "Countdown: X" string
                    final countText = snapshot.data ?? "Countdown: 5";
                    final countValue = int.tryParse(countText.split(": ")[1]) ?? 5;
                    
                    return Text(
                      "$countValue",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            StreamBuilder<String>(
              stream: statusStream,
              initialData: "Countdown: 5",
              builder: (context, snapshot) {
                // Extract number from "Countdown: X" string
                final countText = snapshot.data ?? "Countdown: 5";
                final countValue = int.tryParse(countText.split(": ")[1]) ?? 5;
                
                // Calculate correct progress - reverse the calculation since countdown goes down
                final progress = countValue / 5;
                
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress, // Progress based on countdown
                      backgroundColor: Colors.red.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Sending SOS in $countValue ${countValue == 1 ? 'second' : 'seconds'}...",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.pop(context); // Close dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "I'M SAFE - CANCEL SOS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      );
    },
  );
}

  // Trigger the actual SOS process after countdown
  void _triggerSOS() {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop(); // Close the dialog
    }
    
    // Update status
    _isSending = true;
    _sosStatus = "Sending SOS signal...";
    _statusController.add(_sosStatus);
    
    // Use BleService to trigger SOS
    _bleService.triggerSOS().then((success) {
      _isSending = false;
      _sosStatus = success 
          ? "SOS signal sent successfully!" 
          : "Failed to send SOS. Using cloud backup.";
      _statusController.add(_sosStatus);
      
      // Also send to Firebase as backup
      _sendSOS();
      
      // Show result notification if we have a valid BuildContext
      if (_dialogContext != null && navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(_sosStatus),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }).catchError((error) {
      _isSending = false;
      _sosStatus = "Error: Using cloud backup";
      _statusController.add(_sosStatus);
      
      // Fallback to Firebase
      _sendSOS();
    });
  }

  void _sendSOS() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("sos_trigger/$userId");
      ref.set({
        "triggered": true,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      }).then((_) {
        print("✅ SOS Triggered!");
      }).catchError((error) {
        print("❌ Failed to trigger SOS: $error");
      });
    }
  }

  // Check BLE connection
  void _checkBleConnection() async {
    if (!_bleService.isConnected) {
      await _bleService.scanAndConnect();
    }
  }

  // Navigate to emergency screen
  void _navigateToEmergencyScreen() {
    // Use navigator key to navigate to emergency screen
    navigatorKey.currentState?.pushNamed('/emergency');
  }

  // Clean up resources
  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}