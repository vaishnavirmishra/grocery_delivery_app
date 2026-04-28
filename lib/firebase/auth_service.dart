import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🟢 SIGNUP
  Future<User?> signup(String email, String password, String role) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "email": email,
          "role": role,
          "uid": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });

        print("🔥 User saved in Firestore: ${user.uid}");
      }

      return user;
    } catch (e) {
      print("❌ Signup error: $e");
      rethrow;
    }
  }

  // 🔵 LOGIN
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } catch (e) {
      print("❌ Login error: $e");
      rethrow;
    }
  }

  // 🟣 GET ROLE (FIXED)
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        return data?['role']; // safe access
      }

      print("⚠️ No user document found for $uid");
      return null;
    } catch (e) {
      print("❌ Role error: $e");
      return null;
    }
  }
}