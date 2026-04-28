import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RiderLocationService {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> startTracking(String orderId) async {

    print("🚀 SERVICE CALLED");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("❌ GPS OFF");
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ PERMISSION ISSUE");
      return;
    }

    print("✅ GPS + PERMISSION OK");

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) async {

      print("📍 LOCATION RECEIVED");

      print("${position.latitude} , ${position.longitude}");

      await firestore.collection("orders").doc(orderId).set({
        "riderLocation": {
          "lat": position.latitude,
          "lng": position.longitude,
        }
      }, SetOptions(merge: true));

      print("🔥 FIRESTORE UPDATED");
    });
  }
}