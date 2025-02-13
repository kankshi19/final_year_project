import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class ManageWearableScreen extends StatefulWidget {
  @override
  _ManageWearableScreenState createState() => _ManageWearableScreenState();
}

class _ManageWearableScreenState extends State<ManageWearableScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  String receivedData = "";
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
  }

  /// Scan and Connect to Raspberry Pi
  void scanAndConnect() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10)); // Increased scan timeout

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        print("Device found: ${result.device.name} (${result.device.id})");

        if (result.device.name == "nirbhaya") { // Check for the Raspberry Pi device name
          print("Found Raspberry Pi with name 'nirbhaya'");

          FlutterBluePlus.stopScan(); // Stop scanning once device is found
          await result.device.connect();
          connectedDevice = result.device;
          isConnected = true;
          print("Connected to Raspberry Pi.");

          // Discover services and characteristics
          List<BluetoothService> services =
              await connectedDevice!.discoverServices();
          for (BluetoothService service in services) {
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              if (characteristic.properties.write) {
                writeCharacteristic = characteristic;
              }
              if (characteristic.properties.notify) {
                characteristic.value.listen((value) {
                  setState(() {
                    receivedData = utf8.decode(value);
                  });
                });
                await characteristic.setNotifyValue(true);
              }
            }
          }
          setState(() {});
          break;
        }
      }
    });
  }

  /// Send Data to Raspberry Pi
  void sendDataToRaspberryPi(String data) async {
    if (writeCharacteristic != null) {
      await writeCharacteristic!.write(utf8.encode(data));
      print("Sent: $data");
    } else {
      print("No write characteristic available.");
    }
  }

  /// Sync Firebase Data with Raspberry Pi
  void syncFirebaseData() async {
    DatabaseReference ref = _database.ref("users/location");

    ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      double latitude = data['latitude'];
      double longitude = data['longitude'];
      print("📡 Firebase Updated Location: $latitude, $longitude");

      // Send updated location to Raspberry Pi
      sendDataToRaspberryPi("LAT:$latitude,LON:$longitude");
    });
  }

  /// Test SOS Feature
  void testSOS() {
    sendDataToRaspberryPi("TEST_SOS");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("SOS test command sent to Raspberry Pi.")),
    );
  }

  /// Test GPS Functionality
  void testGPS() {
    sendDataToRaspberryPi("TEST_GPS");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("GPS test command sent to Raspberry Pi.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Wearable Device"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Device Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              isConnected
                  ? "Connected to Raspberry Pi"
                  : "Not Connected. Please scan and connect.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: scanAndConnect,
              child: Text(isConnected ? "Reconnect" : "Scan & Connect"),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              "Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isConnected ? syncFirebaseData : null,
              child: Text("Sync Firebase Data"),
            ),
            ElevatedButton(
              onPressed: isConnected ? testSOS : null,
              child: Text("Test SOS Feature"),
            ),
            ElevatedButton(
              onPressed: isConnected ? testGPS : null,
              child: Text("Test GPS Functionality"),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              "Received Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                receivedData.isEmpty ? "No data received yet." : receivedData,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
