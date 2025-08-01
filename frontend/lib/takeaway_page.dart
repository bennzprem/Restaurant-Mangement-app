import 'package:flutter/material.dart';

class TakeawayPage extends StatelessWidget {
  const TakeawayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takeaway')),
      body: const Center(
        child: Text(
          'Takeaway Service - Coming Soon!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}