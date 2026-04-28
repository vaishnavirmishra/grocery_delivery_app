import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // 🛒 PLACE ORDER FUNCTION
  static Future<void> placeOrder({
    required String userId,
    required String productId,
    required String productName,
    required String image,
    required int price,
    required int quantity,
  }) async {
    try {
      await _firestore.collection("orders").add({
        "userId": userId,
        "productId": productId,
        "productName": productName,
        "image": image,
        "price": price,
        "quantity": quantity,
        "totalPrice": price * quantity,
        "status": "placed",
        "date": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception("Order failed: $e");
    }
  }

  // 📦 GET USER ORDERS STREAM
  static Stream<QuerySnapshot> getUserOrders(String userId) {
    return _firestore
        .collection("orders")
        .where("userId", isEqualTo: userId)
        .orderBy("date", descending: true)
        .snapshots();
  }

  // ❌ CANCEL ORDER
  static Future<void> cancelOrder(String orderId) async {
    await _firestore.collection("orders").doc(orderId).update({
      "status": "cancelled",
    });
  }

  // 🗑 DELETE ORDER
  static Future<void> deleteOrder(String orderId) async {
    await _firestore.collection("orders").doc(orderId).delete();
  }
}