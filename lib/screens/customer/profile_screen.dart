import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temp_fix/screens/customer/my_order_screen.dart';
import 'package:temp_fix/screens/customer/setting_screen.dart';
import 'package:temp_fix/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return const Center(child: Text("No Profile Found"));
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),

                const SizedBox(height: 20),

                Text(
                  data["name"] ?? "No Name",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(data["email"] ?? "No Email"),

                const SizedBox(height: 30),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: const Text("My Orders"),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_)=> MyOrdersScreen(userId: userId)));
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>  SettingsScreen(userId: userId,)));
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(role: "customer",)),
                            (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}