import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'location_tracking_page.dart';

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _acceptedOrder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.id;
      print('Current user ID: $userId');

      // Load ready orders (for accepting)
      final readyResp = await _fetchJson('${_api.baseUrl}/api/delivery/orders');

      // Load accepted orders (for this delivery person)
      // Only fetch accepted orders if user is logged in
      List<dynamic> acceptedResp = [];
      if (userId != null) {
        try {
          acceptedResp = await _fetchJson(
              '${_api.baseUrl}/api/delivery/accepted-orders?delivery_user_id=$userId');
        } catch (e) {
          print('Error fetching accepted orders: $e');
          acceptedResp = [];
        }
      } else {
        print('User not logged in, skipping accepted orders fetch');
      }

      if (!mounted) return;
      print('Ready orders: ${readyResp.length}');
      print('Accepted orders: ${acceptedResp.length}');
      print('Accepted orders data: $acceptedResp');
      setState(() {
        _orders = (readyResp as List).cast<Map<String, dynamic>>();
        _acceptedOrder = acceptedResp.isNotEmpty
            ? acceptedResp.first as Map<String, dynamic>
            : null;
        _loading = false;
      });
      print(
          'Final state - orders: ${_orders.length}, accepted: ${_acceptedOrder != null}');
      if (_acceptedOrder != null) {
        print('Accepted order details: $_acceptedOrder');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    }
  }

  Future<dynamic> _fetchJson(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw 'HTTP ${resp.statusCode}: ${resp.body}';
    }
    return convert.jsonDecode(resp.body);
  }

  Future<void> _acceptOrder(int orderId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to accept orders')),
      );
      print('ERROR: User not logged in, cannot accept order');
      return;
    }

    print('User is logged in with ID: $userId, accepting order $orderId');

    try {
      final resp = await http.post(
        Uri.parse('${_api.baseUrl}/api/delivery/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({'delivery_user_id': userId}),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order accepted successfully!')));
          print('Order accepted, refreshing dashboard...');
          _load();
        }
      } else {
        print('Order acceptance failed: ${resp.statusCode} - ${resp.body}');
        throw 'Server responded ${resp.statusCode}: ${resp.body}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _acceptedOrder != null
              ? _buildAcceptedOrderView()
              : _orders.isEmpty
                  ? const Center(child: Text('No ready orders'))
                  : _buildReadyOrdersView(),
    );
  }

  Widget _buildAcceptedOrderView() {
    final order = _acceptedOrder!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary accepted order card
            Card(
              elevation: 8,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order['order_id']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACCEPTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Customer: ${order['customer_name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ₹${(order['total_amount'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Address: ${order['delivery_address'] ?? 'No address'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationTrackingPage(
                                deliveryAddress:
                                    order['delivery_address'] ?? '',
                                customerName: order['customer_name'] ?? '',
                                orderId: order['order_id'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('View Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No other orders available while you have an active delivery',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyOrdersView() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final o = _orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                  'Order #${o['order_id']} • ₹${(o['total_amount'] ?? 0).toStringAsFixed(0)}'),
              subtitle:
                  Text('${o['customer_name']}\n${o['delivery_address'] ?? ''}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () => _acceptOrder(o['order_id'] as int),
                child: const Text('Accept'),
              ),
            ),
          );
        },
      ),
    );
  }
}
