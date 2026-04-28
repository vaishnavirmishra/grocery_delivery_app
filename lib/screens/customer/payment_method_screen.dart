import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String selected = "COD";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPaymentMethod();
  }

  //////////////////////////////////////////////////////
  // 🔥 LOAD FROM FIRESTORE
  //////////////////////////////////////////////////////
  Future<void> loadPaymentMethod() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()!["defaultPayment"] != null) {
      selected = doc.data()!["defaultPayment"];
    }

    setState(() => loading = false);
  }

  //////////////////////////////////////////////////////
  // 💾 SAVE TO FIRESTORE
  //////////////////////////////////////////////////////
  Future<void> savePaymentMethod(String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => selected = value);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
      "defaultPayment": value,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment method updated ✅")),
    );
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Methods"),
        backgroundColor: Colors.green,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          RadioListTile(
            value: "COD",
            groupValue: selected,
            title: const Text("Cash on Delivery"),
            onChanged: (v) => savePaymentMethod(v!),
          ),

          RadioListTile(
            value: "RAZORPAY",
            groupValue: selected,
            title: const Text("Online Payment (UPI / Card)"),
            onChanged: (v) => savePaymentMethod(v!),
          ),
        ],
      ),
    );
  }
}