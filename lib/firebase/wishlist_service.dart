import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addToWishlist(Map<String, dynamic> product) async {
    final ref = _db.collection("wishlist").doc(uid);

    await ref.set({
      "items": {
        product["id"]: {
          "id": product["id"],
          "name": product["name"],
          "price": product["price"],
          "image": product["image"],
        }
      }
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> wishlistStream() {
    return _db.collection("wishlist").doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data["items"] == null) return [];

      final items = Map<String, dynamic>.from(data["items"]);

      return items.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  Future<void> removeItem(String id) async {
    await _db.collection("wishlist").doc(uid).update({
      "items.$id": FieldValue.delete(),
    });
  }
}