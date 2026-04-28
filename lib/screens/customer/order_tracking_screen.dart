import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? mapController;

  LatLng riderPos = const LatLng(26.4499, 80.3319);
  LatLng storePos = const LatLng(26.4499, 80.3319);
  LatLng customerPos = const LatLng(26.4499, 80.3319);

  Set<Polyline> polylines = {};

  bool goingToStore = true;
  bool isMoving = false;

  @override
  void initState() {
    super.initState();
    initTracking();
  }

  //////////////////////////////////////////////////////
  /// INIT
  //////////////////////////////////////////////////////
  Future<void> initTracking() async {
    await getCurrentLocation();
    listenOrder();
  }

  //////////////////////////////////////////////////////
  /// GET CURRENT LOCATION
  //////////////////////////////////////////////////////
  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition();

    riderPos = LatLng(position.latitude, position.longitude);

    setState(() {});
  }

  //////////////////////////////////////////////////////
  /// LISTEN FIRESTORE
  //////////////////////////////////////////////////////

  void listenOrder() {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) async {
          if(isMoving) return;
      final data = snapshot.data();

      if (data != null) {
        storePos = LatLng(data["storeLat"], data["storeLng"]);
        customerPos = LatLng(data["customerLat"], data["customerLng"]);

        if (goingToStore) {
          await moveRider(storePos);

          goingToStore = false;

          await FirebaseFirestore.instance
              .collection("orders")
              .doc(widget.orderId)
              .update({"status": "picked"});
        } else {
          await moveRider(customerPos);

          await FirebaseFirestore.instance
              .collection("orders")
              .doc(widget.orderId)
              .update({"status": "delivered"});
        }
      }
    });
  }

  //////////////////////////////////////////////////////
  /// MOVE RIDER
  //////////////////////////////////////////////////////
  Future<void> moveRider(LatLng destination) async {
    isMoving = true;
    List<LatLng> routePoints = await getPolylinePoints(riderPos, destination);

    polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        points: routePoints,
        width: 5,
        color: Colors.blue,
      ),
    };

    setState(() {});

    for (LatLng point in routePoints) {
      riderPos = point;

      mapController?.animateCamera(
        CameraUpdate.newLatLng(riderPos),
      );

      setState(() {});

      await FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId)
          .update({
        "riderLat": riderPos.latitude,
        "riderLng": riderPos.longitude,
      });

      await Future.delayed(const Duration(milliseconds: 500));
    }
    isMoving = false;
  }

  //////////////////////////////////////////////////////
  /// GET DIRECTIONS
  //////////////////////////////////////////////////////
  Future<List<LatLng>> getPolylinePoints(
      LatLng start, LatLng end) async {
    List<LatLng> polylineCoordinates = [];

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start.latitude},${start.longitude}"
        "&destination=${end.latitude},${end.longitude}"
        "&key=AIzaSyDFlj9etT4eiz8SlziZnN-J-DF2dCnmR5M";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["routes"].isNotEmpty) {
      String points = data["routes"][0]["overview_polyline"]["points"];
      polylineCoordinates = decodePolyline(points);
    }

    return polylineCoordinates;
  }

  //////////////////////////////////////////////////////
  /// DECODE POLYLINE
  //////////////////////////////////////////////////////
  List<LatLng> decodePolyline(String poly) {
    List<LatLng> points = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  //////////////////////////////////////////////////////
  /// UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Order 🚚"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: riderPos,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId("rider"),
                  position: riderPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                  infoWindow: const InfoWindow(title: "Rider"),
                ),
                Marker(
                  markerId: const MarkerId("store"),
                  position: storePos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                  infoWindow: const InfoWindow(title: "Store"),
                ),
                Marker(
                  markerId: const MarkerId("customer"),
                  position: customerPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: const InfoWindow(title: "Customer"),
                ),
              },
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .doc(widget.orderId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final data =
                snapshot.data!.data() as Map<String, dynamic>;

                String status = data["status"] ?? "pending";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order ID: ${widget.orderId}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("Status: $status"),
                    const SizedBox(height: 10),
                    const Text("Rider is on the way 🚀"),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}