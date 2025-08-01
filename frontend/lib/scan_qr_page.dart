import 'package:flutter/material.dart';

class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order from Table')),
      body: const Center(
        child: Text(
          'QR Code Scanner - Coming Soon!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
