import 'package:flutter/material.dart';

class KitchenDashboardPage extends StatelessWidget {
  const KitchenDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Dashboard')),
      body: const Center(child: Text('Welcome, Kitchen Staff')),
    );
  }
}
