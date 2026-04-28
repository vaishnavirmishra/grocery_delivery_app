import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool loading = false;
  bool obscure = true;

  //////////////////////////////////////////////////////
  // 🔐 CHANGE PASSWORD LOGIC
  //////////////////////////////////////////////////////
  Future<void> changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (newPassController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 🔥 RE-AUTHENTICATE
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassController.text,
      );

      await user.reauthenticateWithCredential(cred);

      // 🔥 UPDATE PASSWORD
      await user.updatePassword(newPassController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password Updated Successfully ✅")),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String msg = "Error";

      if (e.code == "wrong-password") {
        msg = "Old password is incorrect";
      } else if (e.code == "weak-password") {
        msg = "Password should be at least 6 characters";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }

    setState(() => loading = false);
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: oldPassController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: "Old Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: newPassController,
              obscureText: obscure,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: confirmPassController,
              obscureText: obscure,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: loading ? null : changePassword,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update Password"),
              ),
            )
          ],
        ),
      ),
    );
  }
}