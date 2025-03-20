import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static List<Map<String, String>> _predefinedSafetyTips = [];
  static String? _lastZone; // Track last zone to prevent duplicate notifications

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitialize = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(android: androidInitialize);

    await _notificationsPlugin.initialize(initializationSettings);

    await _requestPermissions();
    await _loadPredefinedTips();
    await createNotificationChannelGroup();

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    await Workmanager().registerPeriodicTask(
    "safety-tips-task",
    "showSafetyTipTask",
    frequency: const Duration(minutes: 45), // Minimum 15 minutes on Android
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.linear,
    constraints: Constraints(
      networkType: NetworkType.not_required, // No network required
      requiresBatteryNotLow: false, // Works on low battery
      requiresCharging: false, // Works without charging
      requiresDeviceIdle: false, // Works when not idle
    ),
);
    await registerTestTask();
  }

  static void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Executing task: $task");
    if (task == "showSafetyTipTask") {
      await showSafetyTipNotification();
    }
    return Future.value(true);
  });
}

  static Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  static Future<bool> _checkPermissions() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return true;
  }

  static Future<void> _loadPredefinedTips() async {
    try {
      final String response = await rootBundle.loadString('assets/safety_tips.json');
      List<dynamic> jsonData = json.decode(response);

      _predefinedSafetyTips = jsonData.map((item) {
        return {
          "title": item["title"].toString(),
          "body": item["body"].toString()
        };
      }).toList();
    } catch (e) {
      print("Error loading safety tips: $e");
      _predefinedSafetyTips = [
        {"title": "Stay Alert", "body": "Be aware of your surroundings."},
        {"title": "Emergency Contacts", "body": "Ensure contacts are accessible."},
      ];
    }
  }

  static Future<void> showSafetyTipNotification() async {
    if (_predefinedSafetyTips.isEmpty) {
      await _loadPredefinedTips();
    }

    final Random random = Random();
    final tip = _predefinedSafetyTips[random.nextInt(_predefinedSafetyTips.length)];

    await showNotification(
      id: random.nextInt(1000),
      title: tip["title"]!,
      body: tip["body"]!,
      importance: Importance.low,
    );
  }

  static Future<void> showZoneAlert({
    required String zone,
    required double safetyScore,
  }) async {
    if (zone == _lastZone) return;

    String title;
    String body;
    Importance importance;

    switch (zone) {
      case "Red (Unsafe)":
        title = "⚠️ HIGH RISK AREA ALERT";
        body = "Safety score: ${safetyScore.toStringAsFixed(1)}. Stay vigilant.";
        importance = Importance.high;
        break;
      case "Yellow (Moderate Safety)":
        title = "⚠️ CAUTION ZONE";
        body = "Safety score: ${safetyScore.toStringAsFixed(1)}. Be cautious.";
        importance = Importance.high;
        break;
      case "Green (Safe)":
        title = "✅ SAFE ZONE";
        body = "Safe area (Score: ${safetyScore.toStringAsFixed(1)}).";
        importance = Importance.low;
        break;
      default:
        return;
    }

    await showNotification(
      id: 2000,
      title: title,
      body: body,
      importance: importance,
    );

    _lastZone = zone;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required Importance importance,
  }) async {
    try {
      if (!await _checkPermissions()) {
        print("Notification permission not granted.");
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'women_safety_channel',
        'Women Safety Alerts',
        channelDescription: 'Notifications for safety alerts and tips',
        importance: importance,
        priority: importance == Importance.high ? Priority.high : Priority.low,
        playSound: importance == Importance.high,
        enableVibration: importance == Importance.high,
        channelShowBadge: true,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body),
        color: const Color.fromARGB(255, 157, 47, 64),
      );

      final details = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(id, title, body, details);
    } catch (e) {
      print("Error displaying notification: $e");
    }
  }


  static Future<void> createNotificationChannelGroup() async {
    const groupId = 'women_safety_group';
    const groupName = 'Safety Alerts Group';

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          AndroidNotificationChannelGroup(groupId, groupName),
        );
  }

  static Future<void> registerTestTask() async {
    await Workmanager().registerOneOffTask(
      "test-task",
      "simpleTask",
      initialDelay: const Duration(seconds: 10),
    );
  }


  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
