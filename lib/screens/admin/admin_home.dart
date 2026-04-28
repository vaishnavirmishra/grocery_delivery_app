import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temp_fix/screens/admin/add_store_view.dart';
import 'package:temp_fix/screens/admin/order_list.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel 🛠"),
        backgroundColor: Colors.green,
      ),

      body: isDesktop
          ? Row(
        children: [
          // 🟢 LEFT MENU
          Container(
            width: 250,
            color: Colors.green.shade100,
            child: Column(
              children: [
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Orders"),
                  onTap: () => setState(() => selectedIndex = 0),
                ),
                ListTile(
                  title: const Text("Stores"),
                  onTap: () => setState(() => selectedIndex = 1),
                ),
              ],
            ),
          ),

          // 🔵 RIGHT SIDE
          Expanded(
            child: selectedIndex == 0
                ? const OrdersList()
                : Column(
              children: [
                const AddStoreView(), // ➕ Add Store
                const Divider(),
                const Expanded(child: StoreListView()), // 📋 Store List
              ],
            ),
          ),
        ],
      )
          : const OrdersList(),
    );
  }
}

//////////////////////////////////////////////////////////
// 🏪 STORE LIST VIEW (ADD THIS BELOW)
//////////////////////////////////////////////////////////

class StoreListView extends StatelessWidget {
  const StoreListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("stores").snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stores = snapshot.data!.docs;

        if (stores.isEmpty) {
          return const Center(child: Text("No Stores Found"));
        }

        return ListView.builder(
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            final data = store.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(data['name'] ?? ""),
                subtitle: Text(data['address'] ?? ""),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ✅ ACTIVE TOGGLE
                    Switch(
                      value: data['active'] ?? true,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection("stores")
                            .doc(store.id)
                            .update({"active": val});
                      },
                    ),

                    // ❌ DELETE
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection("stores")
                            .doc(store.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}