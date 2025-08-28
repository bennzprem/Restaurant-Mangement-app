import 'package:flutter/material.dart';

class DeliveryDashboardPage extends StatelessWidget {
  const DeliveryDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Dashboard')),
      body: const Center(child: Text('Welcome, Delivery Staff')),
    );
  }
}
