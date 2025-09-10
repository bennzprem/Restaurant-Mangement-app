import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'api_service.dart';
import 'models.dart';
import 'theme.dart';
import 'waiter_order_status_page.dart';
import 'package:intl/intl.dart';
import 'services/payment_service.dart';

class WaiterOrdersPage extends StatefulWidget {
  const WaiterOrdersPage({super.key});

  @override
  State<WaiterOrdersPage> createState() => _WaiterOrdersPageState();
}

class _WaiterOrdersPageState extends State<WaiterOrdersPage> {
  final ApiService _api = ApiService();
  List<Order> _orders = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Light polling so list reflects kitchen updates
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    setState(() => _loading = true);
    try {
      final all = await _api.getAllOrders();
      final filtered = all.where((o) => o.userId == auth.user?.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _orders = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return AppTheme.successColor;
      case 'Completed':
        return AppTheme.primaryColor;
      case 'Paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Table Orders'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      final dateStr =
                          DateFormat('MMM d, HH:mm').format(o.createdAt);
                      return _OrderTile(
                        order: o,
                        dateStr: dateStr,
                        statusColor: _statusColor(o.status),
                        onOpenStatus: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WaiterOrderStatusPage(orderId: o.id),
                            ),
                          );
                        },
                        onPaymentCompleted: _load,
                      );
                    },
                  ),
                ),
    );
  }
}

class _OrderTile extends StatefulWidget {
  final Order order;
  final String dateStr;
  final Color statusColor;
  final VoidCallback onOpenStatus;
  final VoidCallback onPaymentCompleted;

  const _OrderTile({
    required this.order,
    required this.dateStr,
    required this.statusColor,
    required this.onOpenStatus,
    required this.onPaymentCompleted,
  });

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  final ApiService _api = ApiService();
  Future<List<Map<String, dynamic>>>? _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _api.getOrderItems(widget.order.id);
  }

  String? _extractSessionId(String tableInfo) {
    final marker = 'Table Session: ';
    final idx = tableInfo.indexOf(marker);
    if (idx == -1) return null;
    var rest = tableInfo.substring(idx + marker.length);
    final pipe = rest.indexOf('|');
    if (pipe != -1) rest = rest.substring(0, pipe);
    return rest.trim();
  }

  Future<void> _payAndComplete() async {
    try {
      // Show payment dialog
      final paymentSuccess = await _showPaymentDialog();

      if (paymentSuccess) {
        // Update order status to Completed
        await _api.updateOrderStatus(widget.order.id, 'Completed');

        // Close table session
        final sessionId = _extractSessionId(widget.order.deliveryAddress);
        if (sessionId != null && sessionId.isNotEmpty) {
          await _api.closeTableSession(sessionId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Payment successful! Order completed. Table freed.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        widget.onPaymentCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppTheme.errorColor,
              content: Text('Payment failed: $e')),
        );
      }
    }
  }

  Future<bool> _showPaymentDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Process Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Order #${widget.order.id}'),
                  const SizedBox(height: 8),
                  Text(
                      'Amount: ₹${widget.order.totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  const Text('Choose payment method:'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Process Razorpay payment first
                    final success = await PaymentService.processPayment(
                      context: context,
                      amount: widget.order.totalAmount.toInt(),
                      orderId: widget.order.id.toString(),
                      customerName:
                          'Table Customer', // You can get this from order details
                      customerEmail: 'customer@example.com',
                      customerPhone: '9999999999',
                    );

                    if (mounted) {
                      Navigator.of(context).pop(success);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pay with Razorpay'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${o.id}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('₹${o.totalAmount.toStringAsFixed(0)} • ${widget.dateStr}',
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.statusColor),
              ),
              child: Text(
                o.status,
                style: TextStyle(
                    color: widget.statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Text(
          o.deliveryAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text('Receipt',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
                const SizedBox(width: 8),
                if (o.status == 'Ready' ||
                    o.status == 'Completed' ||
                    o.status == 'Paid')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Wait for Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _itemsFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              final items = snap.data!;
              return Column(
                children: [
                  ...items.map((it) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(it['menu_items']?['name'] ??
                                  it['name'] ??
                                  'Item')),
                          Text('x${it['quantity']}'),
                          Text(
                              '₹${(it['price_at_order'] * it['quantity']).toStringAsFixed(0)}'),
                        ],
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₹${o.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onOpenStatus,
                icon: const Icon(Icons.visibility),
                label: const Text('Live Status'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (o.status == 'Paid')
                      ? null
                      : (o.status == 'Ready' || o.status == 'Completed')
                          ? _payAndComplete
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (o.status == 'Ready' || o.status == 'Completed')
                            ? AppTheme.primaryColor
                            : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.payment),
                  label: Text(
                    o.status == 'Paid'
                        ? 'Paid'
                        : (o.status == 'Ready' || o.status == 'Completed')
                            ? 'Pay & Complete'
                            : 'Wait for Ready',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
