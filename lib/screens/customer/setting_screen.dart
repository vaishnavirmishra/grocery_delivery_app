import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temp_fix/screens/customer/about_app.dart';
import 'package:temp_fix/screens/customer/change_password_screen.dart';
import 'package:temp_fix/screens/customer/edit_profile_screen.dart';
import 'package:temp_fix/screens/customer/help_support_screen.dart';
import 'package:temp_fix/screens/customer/payment_method_screen.dart';
import 'package:temp_fix/screens/customer/saved_adress_screen.dart';
import '../../main.dart'; // themeNotifier

class SettingsScreen extends StatefulWidget {
  final String userId; // ✅ IMPORTANT

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.green, // always green
        elevation: 0,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final name = data?["name"] ?? "No Name";
          final email = data?["email"] ?? "No Email";

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // 👤 PROFILE SECTION
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 30, color: Colors.green),
                    ),
                    const SizedBox(width: 15),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style:
                          const TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔧 GENERAL
              const Text(
                "General",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 10),

              // ✅ EDIT PROFILE FIXED
              buildTile(
                context,
                icon: Icons.person,
                title: "Edit Profile",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(userId: widget.userId),
                    ),
                  );
                },
              ),

              buildTile(
                context,
                icon: Icons.location_on,
                title: "Saved Address",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> SavedAddressScreen(userId: widget.userId)));
                },
              ),

              buildSwitchTile(
                context,
                icon: Icons.notifications,
                title: "Notifications",
                value: notifications,
                onChanged: (v) => setState(() => notifications = v),
              ),

              // 🌙 DARK MODE
              buildSwitchTile(
                context,
                icon: Icons.dark_mode,
                title: "Dark Mode",
                value: themeNotifier.value == ThemeMode.dark,
                onChanged: (v) {
                  themeNotifier.value =
                  v ? ThemeMode.dark : ThemeMode.light;
                },
              ),

              const SizedBox(height: 20),

              // 🔐 ACCOUNT
              const Text(
                "Account",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 10),

              buildTile(
                context,
                icon: Icons.lock,
                title: "Change Password",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_)=>ChangePasswordScreen()));
                },
              ),

              buildTile(
                context,
                icon: Icons.payment,
                title: "Payment Methods",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> const PaymentMethodScreen()));
                },
              ),

              const SizedBox(height: 20),

              // ❓ SUPPORT
              const Text(
                "Support",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 10),

              buildTile(
                context,
                icon: Icons.help,
                title: "Help & Support",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> HelpSupportScreen()));
                },
              ),

              buildTile(
                context,
                icon: Icons.info,
                title: "About App",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_)=> AboutAppScreen()));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 TILE
  Widget buildTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:
        Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // 🔹 SWITCH TILE
  Widget buildSwitchTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool value,
        required Function(bool) onChanged,
      }) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary:
        Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}