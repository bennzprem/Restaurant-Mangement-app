import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waiter_cart_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../providers/auth_provider.dart';
import 'waiter_order_status_page.dart';

class WaiterCartPage extends StatelessWidget {
  const WaiterCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waiter Carts')),
      body: _WaiterCartList(),
    );
  }
}

class _WaiterCartList extends StatelessWidget {
  final ApiService _api = ApiService();

  _WaiterCartList();

  @override
  Widget build(BuildContext context) {
    final wc = context.watch<WaiterCartProvider>();
    final auth = context.watch<AuthProvider>();

    // Use provider's public list of sessions with items
    final sessions = wc.activeSessionIds;

    if (sessions.isEmpty) {
      return const Center(child: Text('No active waiter carts yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sessionId = sessions[index];
        final items = wc.items(sessionId).values.toList();
        final total = wc.totalAmount(sessionId);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Table Session: $sessionId',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...items.map((ci) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(ci.menuItem.name)),
                        Text('x${ci.quantity}'),
                        Text(
                            '₹${(ci.menuItem.price * ci.quantity).toStringAsFixed(0)}'),
                      ],
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600)),
                    Text('₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () async {
                              try {
                                // submit to backend as an order for that session
                                final payloadItems = items
                                    .map((ci) => {
                                          'menu_item_id': ci.menuItem.id,
                                          'quantity': ci.quantity,
                                          'price': ci.menuItem.price,
                                        })
                                    .toList();
                                final orderId = await _api.addItemsToOrder(
                                    sessionId: sessionId,
                                    items: payloadItems,
                                    waiterId: auth.user?.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Order submitted')),
                                );
                                context
                                    .read<WaiterCartProvider>()
                                    .clearCart(sessionId);
                                // Navigate to order status tracker for waiter
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => WaiterOrderStatusPage(
                                      orderId: orderId,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      backgroundColor: Theme.of(context).custom.errorColor,
                                      content: Text('Failed: $e')),
                                );
                              }
                            },
                      icon: const Icon(Icons.send),
                      label: const Text('Submit to Kitchen'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => context
                          .read<WaiterCartProvider>()
                          .clearCart(sessionId),
                      child: const Text('Clear Cart'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
