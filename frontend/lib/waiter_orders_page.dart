import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeToOrderChanges();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _subscribeToOrderChanges() {
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn || auth.user?.id == null) return;

      final supabase = Supabase.instance.client;
      _ordersChannel = supabase
          .channel('waiter-orders-${auth.user!.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (payload) async {
              // Only refresh if the order belongs to this waiter
              final orderData = payload.newRecord;
              final orderUserId = orderData['user_id'];
              if (orderUserId == auth.user?.id) {
                // Reload orders to get the latest data
                await _load();
              }
            },
          )
          .subscribe();
    } catch (e) {

      // Fallback to periodic refresh if realtime fails
      Timer.periodic(const Duration(seconds: 10), (_) => _load());
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return Colors.green;
      case 'Completed':
        return Theme.of(context).primaryColor;
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
        backgroundColor: Theme.of(context).primaryColor,
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
                  Text('Cash payment received! Order completed. Table freed.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        widget.onPaymentCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
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
                // Cash Payment Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showCashPaymentConfirmation();
                    if (mounted) {
                      Navigator.of(context).pop(confirmed);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.money),
                  label: const Text('Cash Payment'),
                ),
                const SizedBox(width: 8),
                // Digital Payment Button
                ElevatedButton.icon(
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
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Digital Payment'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _showCashPaymentConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.money, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Cash Payment'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${widget.order.id}'),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ₹${widget.order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Cash Payment Instructions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Collect ₹${widget.order.totalAmount.toStringAsFixed(0)} from the customer\n'
                          '2. Verify the amount received\n'
                          '3. Confirm payment completion',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Have you received the cash payment from the customer?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Cash Received'),
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
                      color: Colors.green,
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
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Error loading items: ${snap.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No items found for this order'),
                );
              }
              return Column(
                children: [
                  ...items.map((it) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                            it['menu_items']?['name'] ??
                                it['name'] ??
                                'Unknown Item',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          )),
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
                            ? Theme.of(context).primaryColor
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
