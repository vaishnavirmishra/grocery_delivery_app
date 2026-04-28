import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddressScreen extends StatefulWidget {
  final String userId;

  const SavedAddressScreen({super.key, required this.userId});

  @override
  State<SavedAddressScreen> createState() => _SavedAddressScreenState();
}

class _SavedAddressScreenState extends State<SavedAddressScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final pinController = TextEditingController();

  //////////////////////////////////////////////////////
  // ➕ ADD ADDRESS
  //////////////////////////////////////////////////////
  Future<void> addAddress() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid details")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("addresses")
        .add({
      "name": nameController.text,
      "address": addressController.text,
      "pincode": pinController.text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    nameController.clear();
    addressController.clear();
    pinController.clear();

    Navigator.pop(context);
  }

  //////////////////////////////////////////////////////
  // 🗑 DELETE ADDRESS
  //////////////////////////////////////////////////////
  Future<void> deleteAddress(String id) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("addresses")
        .doc(id)
        .delete();
  }

  //////////////////////////////////////////////////////
  // ➕ ADD ADDRESS DIALOG
  //////////////////////////////////////////////////////
  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Address"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Label (Home/Office)"),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Full Address"),
            ),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: "Pincode"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: addAddress,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Addresses"),
        backgroundColor: Colors.green,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .collection("addresses")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final addresses = snapshot.data!.docs;

          if (addresses.isEmpty) {
            return const Center(child: Text("No Address Saved"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final data = addresses[index].data();

              return Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),

                  title: Text(
                    data["name"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    "${data["address"]}\n${data["pincode"]}",
                  ),

                  isThreeLine: true,

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteAddress(addresses[index].id),
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