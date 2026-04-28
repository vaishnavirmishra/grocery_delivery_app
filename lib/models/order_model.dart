import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String userId;

  final String storeName;
  final double storeLat;
  final double storeLng;

  final double customerLat;
  final double customerLng;

  final double riderLat;
  final double riderLng;

  final String address;
  final String pincode;

  final String payment;
  final String status;

  final String distance;
  final String eta;

  final double bearing;

  final DateTime createdAt;

  // 🔥 SAFE ITEMS (no crash)
  final Map<String, dynamic> items;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.storeName,
    required this.storeLat,
    required this.storeLng,
    required this.customerLat,
    required this.customerLng,
    required this.riderLat,
    required this.riderLng,
    required this.address,
    required this.pincode,
    required this.payment,
    required this.status,
    required this.distance,
    required this.eta,
    required this.bearing,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {

    final rawItems = map['items'];

    Map<String, dynamic> parsedItems = {};

    // 🔥 HANDLE BOTH LIST & MAP
    if (rawItems is Map) {
      parsedItems = Map<String, dynamic>.from(rawItems);
    }
    else if (rawItems is List) {
      for (var item in rawItems) {
        if (item is Map && item['id'] != null) {
          parsedItems[item['id']] = item;
        }
      }
    }

    return OrderModel(
      orderId: id,
      userId: map['userId'] ?? '',

      storeName: map['storeName'] ?? 'Unknown Store',
      storeLat: (map['storeLat'] ?? 0).toDouble(),
      storeLng: (map['storeLng'] ?? 0).toDouble(),

      customerLat: (map['customerLat'] ?? 0).toDouble(),
      customerLng: (map['customerLng'] ?? 0).toDouble(),

      riderLat: (map['riderLat'] ?? 0).toDouble(),
      riderLng: (map['riderLng'] ?? 0).toDouble(),

      address: map['address'] ?? '',
      pincode: map['pincode'] ?? '',

      payment: map['payment'] ?? '',
      status: map['status'] ?? 'pending',

      distance: map['distance'] ?? '',
      eta: map['eta'] ?? '',

      bearing: (map['bearing'] ?? 0).toDouble(),

      createdAt: (map['createdAt'] as Timestamp).toDate(),

      items: parsedItems, // 🔥 FINAL FIX
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeName': storeName,
      'storeLat': storeLat,
      'storeLng': storeLng,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'riderLat': riderLat,
      'riderLng': riderLng,
      'address': address,
      'pincode': pincode,
      'payment': payment,
      'status': status,
      'distance': distance,
      'eta': eta,
      'bearing': bearing,
      'createdAt': Timestamp.fromDate(createdAt),

      'items': items,
    };
  }
}