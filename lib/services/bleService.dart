import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BleService {
  // Singleton pattern
  static final BleService _instance = BleService._internal();
  
  factory BleService() {
    return _instance;
  }
  
  BleService._internal();
  
  // BLE Configuration - match with ESP32
  final String deviceName = "ESP32-Wearable";
  final String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  final Guid commandUUID = Guid("87654321-4321-4321-4321-abc123456789");
  final Guid gpsUUID = Guid("11223344-5566-7788-99AA-BBCCDDEEFF00");
  final Guid emergencyContactsUUID = Guid("aabbccdd-eeff-1122-3344-556677889900");
  
  // BLE device and characteristics
  BluetoothDevice? esp32Device;
  BluetoothCharacteristic? commandCharacteristic;
  BluetoothCharacteristic? gpsCharacteristic;
  BluetoothCharacteristic? emergencyContactsCharacteristic;
  
  // State variables
  bool isScanning = false;
  bool isConnected = false;
  String connectionStatus = "Disconnected";
  double? latitude;
  double? longitude;
  int batteryLevel = 0;
  bool isEmergencyContactsSent = false;
  List<String> emergencyContacts = [];
  
  // Stream controllers for state updates
  final _connectionStatusController = StreamController<String>.broadcast();
  final _gpsDataController = StreamController<Map<String, dynamic>>.broadcast();
  final _batteryLevelController = StreamController<int>.broadcast();
  
  // Getters for streams
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get gpsDataStream => _gpsDataController.stream;
  Stream<int> get batteryLevelStream => _batteryLevelController.stream;
  
  // Load emergency contacts from Firebase
  Future<void> loadEmergencyContacts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        print("User not logged in");
        return;
      }
      
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .get();
      
      emergencyContacts = snapshot.docs.map((doc) => doc['phone'].toString()).toList();
      print("Emergency contacts loaded: $emergencyContacts");
    } catch (e) {
      print("Error loading emergency contacts: $e");
    }
  }
  
  // Start scanning for ESP32 device
  Future<void> scanAndConnect() async {
  if (isConnected) {
    print("Already connected. No need to scan.");
    _updateConnectionStatus("Connected");
    return;
  }

  if (isScanning) return;

  isScanning = true;
  _updateConnectionStatus("Scanning...");

  try {
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == deviceName) {
          FlutterBluePlus.stopScan();

          esp32Device = result.device;
          _updateConnectionStatus("Found device, connecting...");

          _connectToDevice();
          break;
        }
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && !isConnected) {
        isScanning = false;
        if (connectionStatus == "Scanning...") {
          _updateConnectionStatus("Device not found");
        }
      }
    });
  } catch (e) {
    isScanning = false;
    _updateConnectionStatus("Scan error: ${e.toString()}");
    print("Error during scan: $e");
  }
}

  
  // Connect to the ESP32 device
  Future<void> _connectToDevice() async {
    if (esp32Device == null) return;
    
    try {
      await esp32Device!.connect();
      
      isConnected = true;
      _updateConnectionStatus("Connected");
      
      _discoverServices();
    } catch (e) {
      _updateConnectionStatus("Connection failed: ${e.toString()}");
      isConnected = false;
      print("Connection error: $e");
    }
  }
  
  // Discover BLE services and characteristics
  Future<void> _discoverServices() async {
    if (esp32Device == null) return;
    
    try {
      List<BluetoothService> services = await esp32Device!.discoverServices();
      
      for (var service in services) {
        print("Service found: ${service.uuid}");
        
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          print("Found wearable service");
          
          for (var characteristic in service.characteristics) {
            print("Characteristic found: ${characteristic.uuid}");
            
            if (characteristic.uuid == commandUUID) {
              commandCharacteristic = characteristic;
              print("Found command characteristic: ${characteristic.uuid}");
            }
            
            if (characteristic.uuid == gpsUUID) {
              gpsCharacteristic = characteristic;
              print("Found GPS characteristic: ${characteristic.uuid}");
              
              // Enable notifications for GPS updates
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                characteristic.onValueReceived.listen((value) {
                  _parseGPSData(value);
                });
              }
            }
            
            if (characteristic.uuid == emergencyContactsUUID) {
              emergencyContactsCharacteristic = characteristic;
              print("Found emergency contacts characteristic: ${characteristic.uuid}");
            }
          }
        }
      }
      
      // Send emergency contacts after discovering services
      if (isConnected && !isEmergencyContactsSent && emergencyContacts.isNotEmpty) {
        await sendEmergencyContactsToBLE();
      }
    } catch (e) {
      print("Error discovering services: $e");
      _updateConnectionStatus("Error discovering services: ${e.toString()}");
    }
  }
  
  // Parse GPS data received from ESP32
  void _parseGPSData(List<int> value) {
    String rawData = String.fromCharCodes(value);
    print("Raw GPS data: $rawData");
    
    // Try to parse JSON data - matching ESP32 format: {"lat": 12.34, "lon": 56.78, "bat": 85}
    try {
      Map<String, dynamic> parsedData = jsonDecode(rawData);
      
      // Check for error response
      if (parsedData.containsKey('error')) {
        print("GPS Error: ${parsedData['error']}");
      }
      
      if (parsedData.containsKey('lat')) {
        latitude = parsedData['lat'];
      }
      
      if (parsedData.containsKey('lon')) {
        longitude = parsedData['lon'];
      }
      
      if (parsedData.containsKey('bat')) {
        batteryLevel = parsedData['bat'];
        if (batteryLevel > 100) batteryLevel = 100;
        _batteryLevelController.add(batteryLevel);
      }
      
      // Send GPS data to stream
      _gpsDataController.add(parsedData);
    } catch (e) {
      print("Error parsing GPS data: $e");
      // If JSON parsing fails, try simple format as fallback
      try {
        RegExp latRegex = RegExp(r'LAT:(-?\d+\.\d+)');
        RegExp lonRegex = RegExp(r'LON:(-?\d+\.\d+)');
        RegExp batRegex = RegExp(r'BAT:(\d+)');
        
        var latMatch = latRegex.firstMatch(rawData);
        var lonMatch = lonRegex.firstMatch(rawData);
        var batMatch = batRegex.firstMatch(rawData);
        
        Map<String, dynamic> parsedData = {};
        
        if (latMatch != null) {
          latitude = double.parse(latMatch.group(1)!);
          parsedData['lat'] = latitude;
        }
        if (lonMatch != null) {
          longitude = double.parse(lonMatch.group(1)!);
          parsedData['lon'] = longitude;
        }
        if (batMatch != null) {
          batteryLevel = int.parse(batMatch.group(1)!);
          if (batteryLevel > 100) batteryLevel = 100;
          parsedData['bat'] = batteryLevel;
          _batteryLevelController.add(batteryLevel);
        }
        
        _gpsDataController.add(parsedData);
      } catch (e) {
        print("Failed to parse GPS data with any method: $e");
      }
    }
  }
  
  // Request GPS data from ESP32
  Future<bool> requestGPSData() async {
    if (commandCharacteristic == null) {
      print("Command characteristic not found");
      return false;
    }
    
    try {
      print("Requesting GPS data...");
      await commandCharacteristic!.write(utf8.encode("GET_GPS"));
      return true;
    } catch (e) {
      _updateConnectionStatus("Error requesting GPS data: ${e.toString()}");
      print("Error requesting GPS data: $e");
      return false;
    }
  }
  
  // Send emergency contacts to ESP32
  Future<bool> sendEmergencyContactsToBLE() async {
    if (esp32Device == null || emergencyContactsCharacteristic == null) {
      print("Can't send contacts: Device or characteristic not available");
      return false;
    }
    
    try {
      if (emergencyContacts.isEmpty) {
        await loadEmergencyContacts();
        if (emergencyContacts.isEmpty) {
          print("No emergency contacts available to send");
          return false;
        }
      }
      
      // Format exactly as ESP32 expects - comma-separated list with no spaces
      String contactsString = emergencyContacts.join(',');
      
      print("Sending emergency contacts: $contactsString");
      await emergencyContactsCharacteristic!.write(utf8.encode(contactsString));
      
      isEmergencyContactsSent = true;
      print("Emergency contacts sent successfully");
      return true;
    } catch (e) {
      print("Error sending emergency contacts: $e");
      return false;
    }
  }
  
  // Trigger SOS alert
  Future<bool> triggerSOS() async {
    if (esp32Device == null) {
      print("Cannot send SOS: Device not connected");
      return false;
    }
    
    if (commandCharacteristic == null) {
      print("Cannot send SOS: Command characteristic not found");
      return false;
    }
    
    try {
      // First make sure we have emergency contacts synced
      if (!isEmergencyContactsSent && emergencyContacts.isNotEmpty) {
        await sendEmergencyContactsToBLE();
        await Future.delayed(Duration(milliseconds: 500)); // Wait for contacts to sync
      }
      
      // First get current GPS data to ensure we have fresh coordinates
      await commandCharacteristic!.write(utf8.encode("GET_GPS"));
      await Future.delayed(Duration(milliseconds: 1000)); // Wait for GPS data to update
      
      // Send SOS command to initiate GSM module alert
      print("Sending SOS command to ESP32...");
      await commandCharacteristic!.write(utf8.encode("SEND_SOS"));
      print("SOS command sent to ESP32!");
      
      return true;
    } catch (e) {
      print("Error sending SOS alert: $e");
      _updateConnectionStatus("Error sending SOS alert: ${e.toString()}");
      return false;
    }
  }
  
  // Disconnect from ESP32
  Future<void> disconnectDevice() async {
    if (esp32Device != null && isConnected) {
      try {
        await esp32Device!.disconnect();
        
        isConnected = false;
        _updateConnectionStatus("Disconnected");
        esp32Device = null;
        commandCharacteristic = null;
        gpsCharacteristic = null;
        emergencyContactsCharacteristic = null;
        isEmergencyContactsSent = false;
      } catch (e) {
        _updateConnectionStatus("Error disconnecting: ${e.toString()}");
        print("Error disconnecting: $e");
      }
    }
  }
  
  // Get current location coordinates
  Map<String, double?>? getCurrentLocation() {
    if (latitude != null && longitude != null) {
      return {
        'latitude': latitude,
        'longitude': longitude
      };
    }
    return null;
  }
  
  // Helper method to update connection status
  void _updateConnectionStatus(String status) {
    connectionStatus = status;
    _connectionStatusController.add(status);
  }
  
  // Dispose method to clean up resources
  void dispose() {
  
  if (!isConnected) {
    _gpsDataController.close();
    _connectionStatusController.close();
  _batteryLevelController.close();
  }

  // Do NOT disconnect device on screen close
  // disconnectDevice();
}

}