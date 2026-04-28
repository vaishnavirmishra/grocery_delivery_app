import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // ✅ SAFE ITEMS HANDLING (List + Map both support)
          final rawItems = data['items'];

          List items = [];

          if (rawItems is List) {
            items = rawItems;
          }
          else if (rawItems is Map) {
            items = rawItems.values.toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Order ID: $orderId",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Text("Store: ${data['storeName'] ?? ''}"),
                Text("Status: ${data['status'] ?? ''}"),
                Text("Address: ${data['address'] ?? ''}"),
                Text("Payment: ${data['payment'] ?? ''}"),
                Text("ETA: ${data['eta'] ?? ''}"),

                const SizedBox(height: 20),

                const Text(
                  "Items",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔥 ITEMS LIST
                if (items.isNotEmpty)
                  ...items.map<Widget>((item) {

                    final map = Map<String, dynamic>.from(item);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: (map['image'] ?? '').toString().isNotEmpty
                            ? Image.network(
                          map['image'],
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.fastfood),

                        title: Text(
                          map['name'] ??
                              map['productName'] ??
                              map['title'] ??
                              map['product_name'] ??
                              "No Name",
                        ),

                        subtitle: Text(
                          "Qty: ${map['quantity'] ?? map['qty'] ?? map['count'] ?? 1}",
                        ),

                        trailing: Text(
                          "₹${map['price'] ?? 0}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList()
                else
                  const Text("No items found"),
              ],
            ),
          );
        },
      ),
    );
  }
}