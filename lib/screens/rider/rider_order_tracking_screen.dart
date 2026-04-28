import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderTrackingScreen extends StatefulWidget {
  final String orderId;

  const RiderTrackingScreen({super.key, required this.orderId});

  @override
  State<RiderTrackingScreen> createState() => _RiderTrackingScreenState();
}

class _RiderTrackingScreenState extends State<RiderTrackingScreen> {
  GoogleMapController? mapController;
  LatLng? currentPos;
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  void startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      currentPos = LatLng(position.latitude, position.longitude);

      setState(() {});

      // 🔥 SEND TO FIRESTORE (REAL TIME)
      FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId)
          .update({
        "riderLat": position.latitude,
        "riderLng": position.longitude,
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rider Live Tracking")),
      body: currentPos == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPos!,
          zoom: 16,
        ),
        myLocationEnabled: true,
        markers: {
          Marker(
            markerId: const MarkerId("rider"),
            position: currentPos!,
            infoWindow: const InfoWindow(title: "You (Rider)"),
          ),
        },
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}