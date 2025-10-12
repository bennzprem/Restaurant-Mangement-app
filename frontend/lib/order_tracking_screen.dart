// lib/order_tracking_screen.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Future<String> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = ApiService().fetchOrderStatus(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Theme.of(context).primaryColor, size: 100),
              const SizedBox(height: 20),
              Text(
                'Order Placed Successfully!',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your Order ID is #${widget.orderId}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              FutureBuilder<String>(
                future: _statusFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                        color: Theme.of(context).primaryColor);
                  }
                  if (snapshot.hasError) {
                    return const Text('Could not fetch status.',
                        style: TextStyle(color: Colors.red));
                  }
                  return Chip(
                    label: Text(
                      'Status: ${snapshot.data}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  );
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                child: const Text('Back to Menu'),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
