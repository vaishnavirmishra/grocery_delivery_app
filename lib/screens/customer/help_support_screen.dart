import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> openUrl(String link) async {
    final Uri url = Uri.parse(link);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $link";
    }
  }

  Future<void> sendEmail() async {
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'support@groceryapp.com',
      query: 'subject=Help Needed',
    );

    await launchUrl(email);
  }

  Future<void> makeCall() async {
    final Uri phone = Uri(
      scheme: 'tel',
      path: '9876543210',
    );

    await launchUrl(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.green,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          ListTile(
            leading: const Icon(Icons.email, color: Colors.green),
            title: const Text("Email Support"),
            onTap: sendEmail,
          ),

          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text("Call Support"),
            onTap: makeCall,
          ),

          ListTile(
            leading: const Icon(Icons.web, color: Colors.green),
            title: const Text("Visit Website"),
            onTap: () => openUrl("https://google.com"),
          ),

        ],
      ),
    );
  }
}