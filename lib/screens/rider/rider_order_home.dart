import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:temp_fix/screens/rider/rider_home.dart';

class RiderHome extends StatelessWidget {
  const RiderHome({super.key});

  @override
  Widget build(BuildContext context) {
    final riderId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Dashboard 🚴"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // =============================
            // 🟡 NEW ORDERS
            // =============================
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text("New Orders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("status", isEqualTo: "pending")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(child: Text("No new orders"));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return Card(
                      child: ListTile(
                        title: Text("Order ID: ${order.id}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order["address"] ?? ""),
                            Text("Store: ${order["storeName"] ?? ""}"),
                          ],
                        ),

                        trailing: ElevatedButton(
                          onPressed: () async {

                            // 🔥 CHECK already accepted
                            final doc = await FirebaseFirestore.instance
                                .collection("orders")
                                .doc(order.id)
                                .get();

                            if (doc["status"] != "pending") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Already accepted")),
                              );
                              return;
                            }

                            // 🔥 ASSIGN
                            await FirebaseFirestore.instance
                                .collection("orders")
                                .doc(order.id)
                                .update({
                              "status": "rider_assigned",
                              "riderId": riderId,
                            });

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RiderScreen(orderId: order.id),
                              ),
                            );
                          },
                          child: const Text("Accept"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // =============================
            // 🔵 MY ORDERS
            // =============================
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text("My Orders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("riderId", isEqualTo: riderId)
                  .where("status",
                  whereIn: ["rider_assigned", "picked_up"])
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(child: Text("No assigned orders"));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return Card(
                      color: Colors.green.shade50,
                      child: ListTile(
                        title: Text("Order ID: ${order.id}"),
                        subtitle: Text("Status: ${order["status"]}"),

                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RiderScreen(orderId: order.id),
                              ),
                            );
                          },
                          child: const Text("Track"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}