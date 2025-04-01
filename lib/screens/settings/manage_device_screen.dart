import 'package:flutter/material.dart';
import 'package:safety_app/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../services/bleService.dart';

class ManageWearableScreen extends StatefulWidget {
  @override
  _ManageWearableScreenState createState() => _ManageWearableScreenState();
}

class _ManageWearableScreenState extends State<ManageWearableScreen> {
  // Use the BleService
  final BleService _bleService = BleService();
  
  // State variables for UI
  bool isConnected = false;
  bool isScanning = false;
  String connectionStatus = "Disconnected";
  String gpsData = "No GPS data received";
  double? latitude;
  double? longitude;
  int batteryLevel = 0;

  bool _isConnecting = false;
  bool _isDisconnecting = false;
  
  // Stream subscriptions
  late StreamSubscription<String> _connectionSubscription;
  late StreamSubscription<Map<String, dynamic>> _gpsSubscription;
  late StreamSubscription<int> _batterySubscription;

  @override
  void initState() {
    super.initState();
      isConnected = _bleService.isConnected;
      connectionStatus = isConnected ? "Connected" : "Disconnected";

      // Subscribe to BLE state updates
      _connectionSubscription = _bleService.connectionStatusStream.listen((status) {
        setState(() {
          connectionStatus = status;
          isConnected = _bleService.isConnected;
        });
      });
        
     _gpsSubscription = _bleService.gpsDataStream.listen((data) {
        setState(() {
          latitude = data['lat'];
          longitude = data['lon'];
          gpsData = latitude != null && longitude != null
              ? "Latitude: $latitude, Longitude: $longitude"
              : "No GPS data received";
        });
      });
    
    _batterySubscription = _bleService.batteryLevelStream.listen((level) {
      setState(() {
        batteryLevel = level;
      });
    });

    // Ensure connection is restored
  Future.delayed(Duration(seconds: 1), () {
    if (!_bleService.isConnected) {
      _bleService.scanAndConnect();
    }
  });
    
    // Load emergency contacts and scan for device
    _bleService.loadEmergencyContacts();
    _bleService.scanAndConnect();
  }
  
  @override
  void dispose() {
    // Cancel all stream subscriptions
    _connectionSubscription.cancel();
    _gpsSubscription.cancel();
    _batterySubscription.cancel();
    
    // Clean up BleService resources
    _bleService.dispose();
    super.dispose();
  }

  Future<void> _connectDevice() async {
  if (_isConnecting || _bleService.isConnected) return;
  
  setState(() {
    _isConnecting = true;
  });
  
  await _bleService.scanAndConnect();
  
  setState(() {
    _isConnecting = false;
  });
}
  
  // Add this method to disconnect the device
  Future<void> _disconnectDevice() async {
  if (_isDisconnecting || !_bleService.isConnected) return;
  
  setState(() {
    _isDisconnecting = true;
  });
  
  await _bleService.disconnectDevice();
  
  setState(() {
    _isDisconnecting = false;
  });
}

  Future<void> _requestGPSData() async {
    if (!_bleService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device not connected')),
      );
      return;
    }
    
    await _bleService.requestGPSData();
  }
  
  void openInMaps() async {
    if (latitude != null && longitude != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          // If Google Maps fails, try with geo: URI
          final geoUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude';
          
          if (await canLaunchUrl(Uri.parse(geoUrl))) {
            await launchUrl(Uri.parse(geoUrl));
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Error"),
                content: Text("Could not open maps application"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text("Could not open maps: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isConnected = _bleService.isConnected;
    final bool isScanning = _bleService.isScanning;
    final bool isEmergencyContactsSent = _bleService.isEmergencyContactsSent;
    final List<String> emergencyContacts = _bleService.emergencyContacts;
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Safety Wearable"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
            onPressed: null,
            tooltip: isConnected ? "Connected" : "Not connected",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device status card
              Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Device Status",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConnected ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              connectionStatus,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.device_unknown, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Device: ${_bleService.deviceName}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.battery_full, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Battery: $batteryLevel%",
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: batteryLevel / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: batteryLevel > 20 ? Colors.green : Colors.red,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.bluetooth_searching),
                            label: Text(isScanning ? "Scanning..." : "Connect"),
                            onPressed: (!isConnected && !isScanning) ? _connectDevice : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),

                          OutlinedButton.icon(
                            icon: Icon(Icons.link_off),
                            label: Text("Disconnect"),
                            onPressed: isConnected ? _disconnectDevice : null, // Only enable if connected
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Location data card
              Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location Data",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gpsData),
                            if (latitude != null && longitude != null)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  "Coordinates: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.my_location),
                            label: Text("Get Location"),
                            onPressed: isConnected ? () => _bleService.requestGPSData() : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                          ),
                          OutlinedButton.icon(
                            icon: Icon(Icons.map),
                            label: Text("View on Map"),
                            onPressed: isConnected && latitude != null && longitude != null ? openInMaps : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // SOS Button
              Card(
                elevation: 3,
                color: Colors.red.shade50,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Press the SOS button to alert emergency contacts with your current location via SMS through the GSM module.",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.emergency, size: 24),
                          label: Text(
                            "SOS ALERT",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: isConnected ? () async {
                            bool success = await _bleService.triggerSOS();
                            if (success) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("SOS Alert Sent"),
                                  content: Text(
                                    "Emergency contacts have been notified with your location via SMS through the GSM module. "
                                    "Your current coordinates: ${latitude != null && longitude != null ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}' : 'Unavailable'}"
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("SOS Alert Failed"),
                                  content: Text("Could not send SOS alert. Please try again."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isConnected && !isEmergencyContactsSent)
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Emergency contacts not yet synced with device. Tap 'Sync Contacts' below to update.",
                                  style: TextStyle(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Emergency Contacts
              Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency Contacts",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        emergencyContacts.isEmpty
                            ? "No emergency contacts loaded yet."
                            : "Your emergency contacts will receive SMS alerts with your location when you activate SOS.",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      if (emergencyContacts.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var contact in emergencyContacts)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 16),
                                      SizedBox(width: 8),
                                      Text(contact),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      OutlinedButton.icon(
                        icon: Icon(Icons.sync),
                        label: Text("Sync Contacts to Device"),
                        onPressed: isConnected && (!isEmergencyContactsSent || emergencyContacts.isEmpty) 
                            ? _bleService.sendEmergencyContactsToBLE
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Device settings
              Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Device Settings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SwitchListTile(
                        title: Text("Fall Detection"),
                        subtitle: Text("Automatically detect falls and send alerts"),
                        value: true,
                        onChanged: isConnected ? (value) {
                          // Toggle fall detection
                        } : null,
                      ),
                      SwitchListTile(
                        title: Text("Location Tracking"),
                        subtitle: Text("Periodically send location updates"),
                        value: true,
                        onChanged: isConnected ? (value) {
                          // Toggle location tracking
                        } : null,
                      ),
                      SwitchListTile(
                        title: Text("Power Saving Mode"),
                        subtitle: Text("Extends battery life with reduced updates"),
                        value: false,
                        onChanged: isConnected ? (value) {
                          // Toggle power saving
                        } : null,
                      ),
                      SwitchListTile(
                        title: Text("GSM Module"),
                        subtitle: Text("Enable SMS alerts through GSM module"),
                        value: true,
                        onChanged: isConnected ? (value) {
                          // Toggle GSM module
                        } : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
