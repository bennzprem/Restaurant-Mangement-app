import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: const Color(0xFFDAE952),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'We would love to hear from you! Reach out to us through any of the following:',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Contact Info
            const ListTile(
              leading: Icon(Icons.location_on, color: Color(0xFFDAE952)),
              title: Text('123 Main Street, City, Country'),
            ),

            const ListTile(
              leading: Icon(Icons.phone, color: Color(0xFFDAE952)),
              title: Text('+1 234 567 890'),
            ),

            const ListTile(
              leading: Icon(Icons.email, color: Color(0xFFDAE952)),
              title: Text('contact@byteeat.com'),
            ),

            const SizedBox(height: 48),

            // Simple Contact Form (optional)
            const TextField(
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Handle submit action here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDAE952),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              ),
              child: const Text('Send Message', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
