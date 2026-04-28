//AIzaSyDFlj9etT4eiz8SlziZnN-J-DF2dCnmR5M
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;
  const CheckoutScreen({super.key, required this.userId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Razorpay razorpay;

  TextEditingController addressController = TextEditingController();
  TextEditingController pinController = TextEditingController();

  String selectedPayment = "COD";
  bool loading = false;

  LatLng? customerLocation;

  @override
  void initState() {
    super.initState();

    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, paymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, paymentError);
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  //////////////////////////////////////////////////////
  // GET LAT LNG
  //////////////////////////////////////////////////////
  Future<LatLng?> getLatLngFromAddress() async {
    try {
      final query =
          "${addressController.text}, ${pinController.text}, Uttar Pradesh, India";

      final url =
          "https://maps.googleapis.com/maps/api/geocode/json"
          "?address=${Uri.encodeComponent(query)}"
          "&key=AIzaSyDFlj9etT4eiz8SlziZnN-J-DF2dCnmR5M";

      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] == "OK") {
        final loc = data["results"][0]["geometry"]["location"];
        return LatLng(loc["lat"], loc["lng"]);
      }
    } catch (e) {
      print("ERROR: $e");
    }
    return null;
  }

  //////////////////////////////////////////////////////
  // DISTANCE
  //////////////////////////////////////////////////////
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;

    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  //////////////////////////////////////////////////////
  // NEAREST STORE
  //////////////////////////////////////////////////////
  Future<Map<String, dynamic>?> getNearestStore(
      double userLat, double userLng) async {
    final snapshot =
    await FirebaseFirestore.instance.collection("stores").get();

    double minDistance = double.infinity;
    Map<String, dynamic>? nearestStore;

    for (var doc in snapshot.docs) {
      final data = doc.data();

      double distance = calculateDistance(
        userLat,
        userLng,
        data["lat"],
        data["lng"],
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestStore = data;
      }
    }

    return nearestStore;
  }

  //////////////////////////////////////////////////////
  // CART ITEMS
  //////////////////////////////////////////////////////
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final doc = await FirebaseFirestore.instance
        .collection("cart")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    final data = doc.data();

    if (data == null || data["items"] == null) return [];

    final items = data["items"] as Map<String, dynamic>;

    return items.entries.map((e) {
      final item = e.value;
      return {
        "id": item["id"],
        "name": item["name"],
        "price": item["price"],
        "image": item["image"],
        "quantity": item["quantity"],
      };
    }).toList();
  }

  //////////////////////////////////////////////////////
  // PAYMENT
  //////////////////////////////////////////////////////
  void paymentSuccess(PaymentSuccessResponse response) {
    createOrder();
  }

  void paymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed")),
    );
  }

  //////////////////////////////////////////////////////
  // CREATE ORDER
  //////////////////////////////////////////////////////
  Future<void> createOrder() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      customerLocation = await getLatLngFromAddress();

      if (customerLocation == null) throw "Location not found";

      final store = await getNearestStore(
        customerLocation!.latitude,
        customerLocation!.longitude,
      );

      if (store == null) throw "No store found";

      final orderRef =
      FirebaseFirestore.instance.collection("orders").doc();

      await orderRef.set({
        "orderId": orderRef.id,
        "userId": user!.uid,
        "address": addressController.text,
        "pincode": pinController.text,

        "customerLat": customerLocation!.latitude,
        "customerLng": customerLocation!.longitude,

        "storeLat": store["lat"],
        "storeLng": store["lng"],
        "storeName": store["name"],

        "payment": selectedPayment,

        "status": "accepted",
        "riderId": "demo_rider",

        // rider starts from store
        "riderLat": store["lat"],
        "riderLng": store["lng"],

        "createdAt": FieldValue.serverTimestamp(),
        "items": await getCartItems(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: orderRef.id),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    }

    setState(() => loading = false);
  }

  //////////////////////////////////////////////////////
  // OPEN PAYMENT
  //////////////////////////////////////////////////////
  void openPayment() {
    var options = {
      "key": "rzp_test_SV4iMpRgiD7zz8",
      "amount": 29900,
      "name": "Grocery App",
      "description": "Order Payment",
    };

    razorpay.open(options);
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Full Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: pinController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Pincode",
                border: OutlineInputBorder(),
              ),
            ),
            RadioListTile(
              value: "COD",
              groupValue: selectedPayment,
              title: const Text("Cash on Delivery"),
              onChanged: (v) {
                setState(() => selectedPayment = v!);
              },
            ),
            RadioListTile(
              value: "RAZORPAY",
              groupValue: selectedPayment,
              title: const Text("Online Payment"),
              onChanged: (v) {
                setState(() => selectedPayment = v!);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () {
                  if (selectedPayment == "RAZORPAY") {
                    openPayment();
                  } else {
                    createOrder();
                  }
                },
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Place Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}