import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await Geolocator.requestPermission();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error fetching location: $e');
      return null;
    }
  }

  Future<void> triggerCheckIn(String userId, DateTime checkInTime, String message, {bool isLocationBased = false}) async {
    Map<String, dynamic> checkInData = {
      'message': message,
      'checkInTime': checkInTime,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (isLocationBased) {
      Position? position = await _getCurrentLocation();
      if (position != null) {
        checkInData['location'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }
    }

    await _firestore.collection('users').doc(userId).collection('check_ins').add(checkInData);
  }

  Stream<QuerySnapshot> getCheckInHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('check_ins')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
