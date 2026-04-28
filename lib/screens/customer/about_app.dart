import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About App"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Icon(Icons.shopping_bag,
                size: 80, color: Colors.green),

            const SizedBox(height: 15),

            const Text(
              "Grocery App",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            const Text(
              "This app allows users to order groceries online with fast delivery and real-time tracking.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 10),

            const ListTile(
              leading: Icon(Icons.person, color: Colors.green),
              title: Text("Developer"),
              subtitle: Text("Vaishnavi Mishra"),
            ),

            const ListTile(
              leading: Icon(Icons.email, color: Colors.green),
              title: Text("Contact"),
              subtitle: Text("vaishnavi972@gmail.com"),
            ),
          ],
        ),
      ),
    );
  }
}