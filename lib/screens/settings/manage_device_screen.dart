import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class ManageWearableScreen extends StatefulWidget {
  @override
  _ManageWearableScreenState createState() => _ManageWearableScreenState();
}

class _ManageWearableScreenState extends State<ManageWearableScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  bool isConnected = false;
  bool isScanning = false;
  String receivedData = "";

  final String deviceName = "ESP32-Wearable"; // Match with ESP32
  final Guid serviceUUID = Guid("12345678-1234-1234-1234-123456789abc");
  final Guid characteristicUUID = Guid("87654321-4321-4321-4321-abc123456789");

  @override
  void initState() {
    super.initState();
    scanAndConnect();
  }

  void scanAndConnect() async {
    setState(() {
      isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.name == deviceName) {
          print("Found ESP32: ${result.device.name}");

          FlutterBluePlus.stopScan();
          await result.device.connect();
          connectedDevice = result.device;
          isConnected = true;
          print("Connected to ESP32!");

          await _discoverServices();
          setState(() {});
          break;
        }
      }
    });
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid == serviceUUID) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == characteristicUUID && characteristic.properties.write) {
            writeCharacteristic = characteristic;
            print("Found writable characteristic!");
          }
        }
      }
    }
  }

  Future<void> sendCommand(String command) async {
    if (writeCharacteristic != null) {
      await writeCharacteristic!.write(utf8.encode(command));
      print("Sent command: $command");
    } else {
      print("No writable characteristic found.");
    }
  }

  void disconnectDevice() {
    if (connectedDevice != null) {
      connectedDevice!.disconnect();
      isConnected = false;
      setState(() {});
      print("Disconnected from ESP32.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Wearable"),
        actions: [
          if (isConnected)
            IconButton(
              icon: Icon(Icons.power_settings_new),
              onPressed: disconnectDevice,
            ),
        ],
      ),
      body: Center(
        child: isConnected
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Connected to ESP32"),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => sendCommand("SOS"),
                    child: Text("Send SOS Command"),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: scanAndConnect,
                child: isScanning ? Text("Scanning...") : Text("Scan & Connect"),
              ),
      ),
    );
  }
}
