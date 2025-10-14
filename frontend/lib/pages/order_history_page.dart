// lib/order_history_page.dart
import 'package:flutter/material.dart';
// You will need to create this model and update api_service.dart in the next steps
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<Order>> _orderHistoryFuture;

  // In _OrderHistoryPageState...
  @override
  void initState() {
    super.initState();
    // Get the userId from the provider and pass it to the service
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId != null) {
      _orderHistoryFuture = ApiService().fetchOrderHistory(userId);
    } else {
      // Handle case where user is not logged in, though this page shouldn't be accessible
      _orderHistoryFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: FutureBuilder<List<Order>>(
        future: _orderHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no past orders.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('Order #${order.id} - ${order.status}'),
                  subtitle: Text(
                    'Placed on: ${DateFormat.yMMMd().format(order.createdAt)}',
                  ),
                  trailing: Text('₹${order.totalAmount.toStringAsFixed(2)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
