import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rider_home.dart';

class AssignedOrdersScreen extends StatelessWidget {
  final String riderId;

  const AssignedOrdersScreen({super.key, required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders 🚴"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("riderId", isEqualTo: riderId)
            .where("status", whereIn: ["rider_assigned", "picked_up"])
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No Orders Assigned"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Order ID: ${order.id}"),
                  subtitle: Text("Status: ${order['status']}"),

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
                    child: const Text("Open"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}