import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================
  // 📦 PRODUCTS
  // =========================

  Stream<QuerySnapshot> getProducts() {
    return _db.collection("products").snapshots();
  }

  Stream<QuerySnapshot> getBanners() {
    return _db.collection("banners").snapshots();
  }

  Stream<QuerySnapshot> searchProducts(String query) {
    return _db.collection("products").snapshots();
  }

  // =========================
  // 🛒 CART (FULL FIXED SYSTEM)
  // =========================

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  /// ➕ ADD TO CART
  Future<void> addToCart(Map<String, dynamic> product) async {
    final ref = _db.collection("cart").doc(uid);

    await ref.set({
      "items": {
        product["id"]: {
          "id": product["id"],
          "name": product["name"],
          "price": product["price"],
          "image": product["image"],
          "quantity": FieldValue.increment(1),
        }
      }
    }, SetOptions(merge: true));
  }

  /// ➕ INCREASE QTY
  Future<void> increaseQty(String productId) async {
    await _db.collection("cart").doc(uid).update({
      "items.$productId.quantity": FieldValue.increment(1),
    });
  }

  /// ➖ DECREASE QTY
  Future<void> decreaseQty(String productId) async {
    await _db.collection("cart").doc(uid).update({
      "items.$productId.quantity": FieldValue.increment(-1),
    });
  }

  /// ❌ REMOVE ITEM
  Future<void> removeFromCart(String productId) async {
    await _db.collection("cart").doc(uid).update({
      "items.$productId": FieldValue.delete(),
    });
  }

  /// 📡 CART STREAM (USE THIS IN CART SCREEN)
  Stream<List<Map<String, dynamic>>> cartStream() {
    return _db.collection("cart").doc(uid).snapshots().map((doc) {
      final data = doc.data();

      if (data == null || data["items"] == null) return [];

      final items = Map<String, dynamic>.from(data["items"]);

      return items.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }
}