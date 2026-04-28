import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> startTracking(String orderId) async {

    print("🚀 Location service started");

    // permission
    await Geolocator.requestPermission();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) async {

      print("📍 ${pos.latitude}, ${pos.longitude}");

      await firestore.collection("orders").doc(orderId).set({
        "riderLocation": {
          "lat": pos.latitude,
          "lng": pos.longitude,
        }
      }, SetOptions(merge: true));

      print("✅ Firestore updated");
    });
  }
}