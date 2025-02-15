import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class ManageWearableScreen extends StatefulWidget {
  @override
  _ManageWearableScreenState createState() => _ManageWearableScreenState();
}

class _ManageWearableScreenState extends State<ManageWearableScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  String receivedData = "";
  bool isConnected = false;
  bool isScanning = false;
  bool isSyncing = false;
  String? userId;
  String batteryLevel = "Unknown";
  String lastSync = "Never";
  List<String> deviceLogs = [];

  @override
  void initState() {
    super.initState();
    getUserId();
    // Start periodic battery check if connected
    _startPeriodicBatteryCheck();
  }

  void _startPeriodicBatteryCheck() {
    Future.delayed(Duration(minutes: 5), () {
      if (isConnected) {
        _checkBatteryLevel();
        _startPeriodicBatteryCheck();
      }
    });
  }

  Future<void> _checkBatteryLevel() async {
    if (writeCharacteristic != null) {
      await writeCharacteristic!.write(utf8.encode("BAT:CHECK"));
    }
  }

  void getUserId() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _loadDeviceLogs();
    }
  }

  void _loadDeviceLogs() {
    if (userId == null) return;
    _database.ref("users/$userId/device_logs").onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          List<dynamic> logs = (event.snapshot.value as List<dynamic>);
          deviceLogs = logs.cast<String>();
        });
      }
    });
  }

void scanAndConnect() async {
  setState(() {
    isScanning = true;
  });

  FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

  FlutterBluePlus.scanResults.listen((results) async {
    for (ScanResult result in results) {
      print("Found device: ${result.device.name} (${result.device.id})");

      if (result.device.name.isNotEmpty && result.device.name.contains("nirbhaya")) {
        print("Found Raspberry Pi: 'nirbhaya'");

        // Stop scanning
        FlutterBluePlus.stopScan();

        // Connect to Raspberry Pi
        await result.device.connect();
        connectedDevice = result.device;
        isConnected = true;
        print("Connected to Raspberry Pi!");

        // Discover services and characteristics
        List<BluetoothService> services = await connectedDevice!.discoverServices();
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

  Future<void> _setupCharacteristics() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          writeCharacteristic = characteristic;
        }
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.value.listen(_handleReceivedData);
        }
      }
    }
    setState(() {});
    _checkBatteryLevel();
  }

  void _handleReceivedData(List<int> value) {
    String data = utf8.decode(value);
    setState(() {
      if (data.startsWith("BAT:")) {
        batteryLevel = data.substring(4);
      } else {
        receivedData = data;
        _addLog("Received: $data");
      }
    });
  }

  void _addLog(String log) {
    setState(() {
      deviceLogs.insert(0, "${DateTime.now()}: $log");
    });
    if (userId != null) {
      _database.ref("users/$userId/device_logs").set(deviceLogs);
    }
  }

  Future<void> syncFirebaseData() async {
    if (userId == null) return;
    setState(() {
      isSyncing = true;
    });

    try {
      DatabaseReference ref = _database.ref("users/$userId/location");
      DatabaseEvent event = await ref.once();
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        
        await sendDataToRaspberryPi("LAT:$latitude,LON:$longitude");
        setState(() {
          lastSync = DateTime.now().toString();
        });
        _addLog("Location data synced successfully");
      }
    } catch (e) {
      _addLog("Sync error: $e");
    } finally {
      setState(() {
        isSyncing = false;
      });
    }
  }

  Future<void> sendDataToRaspberryPi(String data) async {
    if (writeCharacteristic != null) {
      try {
        await writeCharacteristic!.write(utf8.encode(data));
        _addLog("Sent: $data");
      } catch (e) {
        _addLog("Send error: $e");
        throw e;
      }
    }
  }

  Future<void> triggerSOS() async {
    if (userId == null) return;
    
    try {
      DatabaseReference ref = _database.ref("users/$userId/emergency_contacts");
      DatabaseEvent event = await ref.once();
      
      if (event.snapshot.value != null) {
        List<dynamic> contacts = event.snapshot.value as List<dynamic>;
        String contactsStr = contacts.join(",");
        await sendDataToRaspberryPi("SOS:$contactsStr");
        _addLog("SOS triggered");
      } else {
        _addLog("No emergency contacts found");
      }
    } catch (e) {
      _addLog("SOS error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Safety Device Manager"),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (isConnected)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _checkBatteryLevel,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isConnected) {
            await syncFirebaseData();
          }
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              SizedBox(height: 16),
              _buildActionsCard(),
              SizedBox(height: 16),
              _buildLogsCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: isConnected
          ? FloatingActionButton.extended(
              onPressed: triggerSOS,
              icon: Icon(Icons.warning_amber_rounded),
              label: Text("SOS"),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Device Status",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildStatusRow(
              "Connection",
              isConnected ? "Connected" : "Disconnected",
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              isConnected ? Colors.green : Colors.red,
            ),
            SizedBox(height: 8),
            _buildStatusRow(
              "Battery",
              batteryLevel,
              Icons.battery_full,
              Colors.blue,
            ),
            SizedBox(height: 8),
            _buildStatusRow(
              "Last Sync",
              lastSync,
              Icons.sync,
              Colors.orange,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isScanning ? null : scanAndConnect,
              icon: Icon(isScanning ? Icons.hourglass_empty : Icons.bluetooth_searching),
              label: Text(isScanning ? "Scanning..." : "Connect Device"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Text("$label:", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Actions",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isConnected && !isSyncing ? syncFirebaseData : null,
              icon: Icon(Icons.sync),
              label: Text(isSyncing ? "Syncing..." : "Sync Location"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Device Logs",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.clear_all),
                  onPressed: deviceLogs.isEmpty
                      ? null
                      : () {
                          setState(() {
                            deviceLogs.clear();
                          });
                        },
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: deviceLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      deviceLogs[index],
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}