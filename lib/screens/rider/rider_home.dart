//AIzaSyDFlj9etT4eiz8SlziZnN-J-DF2dCnmR5M
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class RiderScreen extends StatefulWidget {
  final String orderId;
  const RiderScreen({super.key, required this.orderId});

  @override
  State<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends State<RiderScreen> {

  GoogleMapController? mapController;

  LatLng riderPos = const LatLng(0, 0);
  LatLng? initialRiderPos;

  LatLng store = const LatLng(0, 0);
  LatLng customer = const LatLng(0, 0);

  List<LatLng> routePoints = [];
  int routeIndex = 0;

  Timer? timer;

  String status = "";
  String lastStatus = "";

  bool initialized = false;
  bool routeLoaded = false;

  final String apiKey = "AIzaSyDFlj9etT4eiz8SlziZnN-J-DF2dCnmR5M";

  @override
  void initState() {
    super.initState();
    initLocation();
    listenOrder();
  }

  //////////////////////////////////////////////////////
  // 📍 GET REAL RIDER LOCATION
  //////////////////////////////////////////////////////
  Future<void> initLocation() async {
    Position pos = await Geolocator.getCurrentPosition();

    riderPos = LatLng(pos.latitude, pos.longitude);

    // 🔥 SAVE ORIGINAL LOCATION
    initialRiderPos = riderPos;

    initialized = true;
    setState(() {});
  }

  //////////////////////////////////////////////////////
  // 🔥 LISTEN ORDER
  //////////////////////////////////////////////////////
  void listenOrder() {
    FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .snapshots()
        .listen((snap) {

      final data = snap.data();
      if (data == null) return;

      status = data["status"];

      store = LatLng(
        (data["storeLat"] as num).toDouble(),
        (data["storeLng"] as num).toDouble(),
      );

      customer = LatLng(
        (data["customerLat"] as num).toDouble(),
        (data["customerLng"] as num).toDouble(),
      );

      // 🔥 RESET ROUTE WHEN STATUS CHANGES
      if (status != lastStatus) {
        lastStatus = status;
        routeLoaded = false;
        routePoints.clear();
        routeIndex = 0;
        timer?.cancel();
      }

      // 🔥 LOAD ROUTE
      if (!routeLoaded && initialized) {
        routeLoaded = true;
        getRoute();
      }

      setState(() {});
    });
  }

  //////////////////////////////////////////////////////
  // 🛣️ GET ROUTE (MAIN LOGIC)
  //////////////////////////////////////////////////////
  Future<void> getRoute() async {

    LatLng start;
    LatLng end;

    if (status == "rider_assigned") {
      // 🔥 Rider → Store
      start = initialRiderPos ?? riderPos;
      end = store;

      print("Route: Rider → Store");
    }
    else if (status == "picked_up") {
      // 🔥 Store → Customer
      start = store;
      end = customer;

      print("Route: Store → Customer");
    }
    else {
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${start.latitude},${start.longitude}"
        "&destination=${end.latitude},${end.longitude}"
        "&key=$apiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["routes"].isEmpty) {
      print("No route found ❌");
      return;
    }

    final encoded = data["routes"][0]["overview_polyline"]["points"];

    PolylinePoints poly = PolylinePoints();

    routePoints = poly.decodePolyline(encoded).map(
          (e) => LatLng(e.latitude, e.longitude),
    ).toList();

    routeIndex = 0;

    startMovement();

    setState(() {});
  }

  //////////////////////////////////////////////////////
  // 🚴 MOVEMENT
  //////////////////////////////////////////////////////
  void startMovement() {

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {

      if (routeIndex >= routePoints.length) {
        timer?.cancel();
        return;
      }

      riderPos = routePoints[routeIndex];
      routeIndex++;

      // 🔥 UPDATE FIRESTORE
      FirebaseFirestore.instance
          .collection("orders")
          .doc(widget.orderId)
          .update({
        "riderLat": riderPos.latitude,
        "riderLng": riderPos.longitude,
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLng(riderPos),
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {

    if (riderPos.latitude == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Rider Tracking 🚴")),

      body: GoogleMap(
        initialCameraPosition:
        CameraPosition(target: riderPos, zoom: 14),
        onMapCreated: (c) => mapController = c,

        markers: {

          Marker(
            markerId: const MarkerId("rider"),
            position: riderPos,
          ),

          Marker(
            markerId: const MarkerId("store"),
            position: store,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ),

          Marker(
            markerId: const MarkerId("customer"),
            position: customer,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
          ),
        },

        polylines: {
          Polyline(
            polylineId: const PolylineId("route"),
            points: routePoints,
            width: 5,
            color: Colors.blue,
          )
        },
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          if (status == "rider_assigned")
            FloatingActionButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("orders")
                    .doc(widget.orderId)
                    .update({"status": "picked_up"});
              },
              child: const Icon(Icons.store),
            ),

          const SizedBox(height: 10),

          if (status == "picked_up")
            FloatingActionButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("orders")
                    .doc(widget.orderId)
                    .update({"status": "delivered"});
              },
              child: const Icon(Icons.check),
            ),
        ],
      ),
    );
  }
}