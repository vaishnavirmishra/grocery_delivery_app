import 'package:flutter/material.dart';
import 'package:temp_fix/screens/login_screen.dart';
import 'package:temp_fix/screens/signup_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String selectedRole = "customer";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Select Your Role 🚀",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            // 🔥 TOGGLE SWITCH
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  roleButton("customer", "Customer 👤"),
                  roleButton("rider", "Rider 🚴"),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🔥 ANIMATED ICON
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                selectedRole == "customer"
                    ? Icons.shopping_cart
                    : Icons.delivery_dining,
                key: ValueKey(selectedRole),
                size: 100,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 50),

            // 🔥 CONTINUE BUTTON
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LoginScreen(role: selectedRole),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 SIGNUP
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SignupScreen(role: selectedRole),
                  ),
                );
              },
              child: const Text(
                "Create new account",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////
  // 🔥 ROLE BUTTON UI
  //////////////////////////////////////////////////////
  Widget roleButton(String role, String title) {
    final isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() => selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}