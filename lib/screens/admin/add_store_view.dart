import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geocoding_services.dart';

class AddStoreView extends StatefulWidget {
  const AddStoreView({super.key});

  @override
  State<AddStoreView> createState() => _AddStoreViewState();
}

class _AddStoreViewState extends State<AddStoreView> {

  // 🟢 NEW: separate controllers
  TextEditingController storeNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  bool loading = false;

  Future<void> addStore() async {
    final name = storeNameController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    LatLng? pos = await GeocodingService.getLatLng(address);

    setState(() => loading = false);

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
      return;
    }

    // 🔥 FIRESTORE SAVE (FIXED)
    await FirebaseFirestore.instance.collection("stores").add({
      "name": name,             // ✅ store name
      "address": address,      // ✅ address
      "lat": pos.latitude,
      "lng": pos.longitude,
      "active": true,
      "createdAt": Timestamp.now(),
    });

    storeNameController.clear();
    addressController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Store Added Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Add Store",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // 🏪 STORE NAME
          TextField(
            controller: storeNameController,
            decoration: const InputDecoration(
              labelText: "Store Name (e.g. Reliance Store)",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          // 📍 ADDRESS
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: "Address (e.g. Kalyani Devi Unnao)",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : addStore,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Add Store"),
            ),
          ),
        ],
      ),
    );
  }
}