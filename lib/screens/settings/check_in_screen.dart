import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/src/date_time.dart';
import '../../services/check_in_service.dart';

class CheckInScreen extends StatefulWidget {
  final String userId;
  const CheckInScreen({super.key, required this.userId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _messageController = TextEditingController();
  DateTime? _selectedTime;
  bool _isLocationBased = false;
  final CheckInService _checkInService = CheckInService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _checkInService.init();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'check_in_channel',
      'Check-In Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, 'Check-In Reminder', message, details);
  }

  Future<void> _scheduleNotification(DateTime scheduledTime, String message) async {
    final androidDetails = const AndroidNotificationDetails(
      'check_in_channel',
      'Check-In Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      0,
      'Check-In Reminder',
      message,
      scheduledTime.toLocal().subtract(const Duration(seconds: 5)).timeZoneOffset as TZDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _scheduleCheckIn() async {
    if (_selectedTime == null || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select time and enter a message.')),
      );
      return;
    }

    await _checkInService.triggerCheckIn(widget.userId, _selectedTime!, _messageController.text);
    await _scheduleNotification(_selectedTime!, _messageController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in scheduled successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Check-In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CheckInHistoryScreen(userId: widget.userId)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Check-In Message', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: const Text('Select Time'),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedTime != null)
                    Text('Selected: ${_selectedTime!.hour}:${_selectedTime!.minute}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Enable Location-Based Check-In'),
                value: _isLocationBased,
                onChanged: (value) {
                  setState(() {
                    _isLocationBased = value;
                  });
                },
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _scheduleCheckIn,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Schedule Check-In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckInHistoryScreen extends StatelessWidget {
  final String userId;
  const CheckInHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-In History')),
      body: Center(
        child: Text('Display check-in history for user: $userId'),
      ),
    );
  }
}