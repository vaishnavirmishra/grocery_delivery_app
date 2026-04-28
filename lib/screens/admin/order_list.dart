import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class OrdersList extends StatelessWidget {
  const OrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Center(child: Text("No Orders Found"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;

            double lat = (data['customerLat'] ?? 0).toDouble();
            double lng = (data['customerLng'] ?? 0).toDouble();

            String status = data['status'] ?? "pending";

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text("Order ID: ${order.id}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Customer: $lat , $lng"),
                    Text("Status: $status"),
                  ],
                ),

                trailing: ElevatedButton(
                  onPressed: () async {
                    await assignNearestStore(order);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Store Assigned ✅"),
                      ),
                    );
                  },
                  child: const Text("Assign Store"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////
// 🔥 DISTANCE FUNCTION
//////////////////////////////////////////////////////////////

double calculateDistance(lat1, lon1, lat2, lon2) {
  double p = 0.017453292519943295;

  double a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) *
          cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p)) /
          2;

  return 12742 * asin(sqrt(a));
}

//////////////////////////////////////////////////////////////
// 🔥 ASSIGN NEAREST STORE (FINAL FIXED)
//////////////////////////////////////////////////////////////

Future<void> assignNearestStore(DocumentSnapshot order) async {
  final orderData = order.data() as Map<String, dynamic>;

  double customerLat = orderData['customerLat'];
  double customerLng = orderData['customerLng'];

  final storesSnapshot =
  await FirebaseFirestore.instance.collection("stores").get();

  double minDistance = double.infinity;

  String? nearestStoreId;
  double? storeLat;
  double? storeLng;

  for (var store in storesSnapshot.docs) {
    final data = store.data();

    double dist = calculateDistance(
      customerLat,
      customerLng,
      data['lat'],
      data['lng'],
    );

    if (dist < minDistance) {
      minDistance = dist;

      nearestStoreId = store.id;
      storeLat = data['lat'];
      storeLng = data['lng'];
    }
  }

  // ✅ UPDATE ORDER WITH STORE LOCATION
  await FirebaseFirestore.instance
      .collection("orders")
      .doc(order.id)
      .update({
    "storeId": nearestStoreId,
    "storeLat": storeLat,
    "storeLng": storeLng,
    "status": "store_assigned",
  });
}