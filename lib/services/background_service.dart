import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundService {
  static final service = FlutterBackgroundService();

  static Future<void> initializeService() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'background_service', // id
      'Background Service', // title
      description: 'This notification keeps the background service running',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true, // Ensures service restarts after reboot
        notificationChannelId: 'background_service',
        initialNotificationTitle: 'Safety Companion',
        initialNotificationContent: 'Tracking your location in the background',
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService(); // Required for Android 10+
      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    // Fetch and update location every 10 seconds
    Timer.periodic(Duration(seconds: 10), (timer) async {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
        LocationPermission permission = await Geolocator.checkPermission();

        if (!isLocationEnabled || permission == LocationPermission.deniedForever) {
          print("Location permission not granted. Stopping service.");
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        String userId = user.uid;

        // Update Firebase Realtime Database
        FirebaseDatabase.instance.ref("users/$userId/location").set({
          "latitude": position.latitude,
          "longitude": position.longitude,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });

        print("Location updated for User: $userId");
      } else {
        print("User is not logged in. Stopping location updates.");
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}
