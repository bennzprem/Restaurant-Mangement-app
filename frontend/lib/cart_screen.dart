// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // 1. Added Razorpay import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

import 'api_service.dart';
import 'cart_provider.dart';
import 'auth_provider.dart';

// 2. Added the main StatefulWidget class definition
class CartScreen extends StatefulWidget {
  final String? tableSessionId;
  const CartScreen({super.key, this.tableSessionId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Razorpay? _razorpay;
  late CartProvider _cart;
  late AuthProvider _auth;
  String? _prefetchedOrderId;
  int _prefetchedAmountPaise = 0;
  bool _isPrefetching = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
    super.dispose();
  }

  Future<void> _prefetchOrder() async {
    if (_isPrefetching) return;
    _cart = Provider.of<CartProvider>(context, listen: false);
    _auth = Provider.of<AuthProvider>(context, listen: false);
    if (_auth.user == null || _cart.items.isEmpty) return;
    _isPrefetching = true;
    try {
      final apiService = ApiService();
      final orderId = await apiService.createRazorpayOrder(_cart.totalAmount);
      setState(() {
        _prefetchedOrderId = orderId;
        _prefetchedAmountPaise = (_cart.totalAmount * 100).round();
      });
    } catch (_) {
      // ignore for now; will retry on next build
    } finally {
      _isPrefetching = false;
    }
  }

  void _openCheckout() {
    // providers
    _cart = Provider.of<CartProvider>(context, listen: false);
    _auth = Provider.of<AuthProvider>(context, listen: false);

    if (_auth.user == null) {
      showLoginPrompt(context);
      return;
    }

    if (_prefetchedOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing payment... please try again.')),
      );
      // trigger prefetch for next click
      _prefetchOrder();
      return;
    }

    final String keyId = 'rzp_test_R9IWhVRyO9Ga0k';

    if (kIsWeb) {
      final options = {
        'key': keyId,
        'order_id': _prefetchedOrderId,
        'amount': _prefetchedAmountPaise,
        'currency': 'INR',
        'name': 'ByteEat',
        'description': 'Food Order Payment',
        'prefill': {'email': _auth.user?.email ?? ''},
        'handler': js.allowInterop((response) {
          _handlePaymentSuccess(PaymentSuccessResponse(
            response['razorpay_payment_id'] ?? '',
            response['razorpay_order_id'] ?? '',
            response['razorpay_signature'] ?? '',
            null,
          ));
        }),
        'modal': {
          'ondismiss': js.allowInterop(() {
            // optional: notify user
          })
        }
      };
      final ctor = js.context['Razorpay'];
      final instance = js.JsObject(ctor, [js.JsObject.jsify(options)]);
      instance.callMethod('open');
    } else {
      final options = {
        'key': keyId,
        'order_id': _prefetchedOrderId,
        'amount': _prefetchedAmountPaise,
        'name': 'ByteEat',
        'description': 'Food Order Payment',
        'prefill': {'email': _auth.user?.email ?? ''},
      };
      _razorpay!.open(options);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final apiService = ApiService();

    // Use the stored member variables, NOT Provider.of(context)
    apiService.placeOrder(
      _cart.items.values.toList(),
      _cart.totalAmount,
      _auth.user!.id,
      '123 Test Address', // TODO: Get a real address from the user before payment
    );

    _cart.clearCart();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! Order Placed.')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '₹');
    final bool isTableMode = widget.tableSessionId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(cartItem.menuItem.imageUrl),
                        ),
                        title: Text(cartItem.menuItem.name),
                        subtitle: Text(
                            currencyFormat.format(cartItem.menuItem.price)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  cart.removeSingleItem(cartItem.menuItem.id),
                            ),
                            Text('${cartItem.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => cart.addItem(cartItem.menuItem),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(currencyFormat.format(cart.totalAmount),
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          if (cart.items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                child: Text(isTableMode ? 'Send to Kitchen' : 'Proceed to Pay'),
                onPressed: () {
                  if (isTableMode) {
                    // Table Mode Logic (Unchanged)
                    Provider.of<CartProvider>(context, listen: false)
                        .clearCart();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Items sent to the kitchen!')),
                    );
                  } else {
                    // Web-safe: open checkout immediately, order prefetched earlier
                    _openCheckout();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

void showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Login Required'),
      content: const Text('You need to be logged in to perform this action.'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        ElevatedButton(
          child: const Text('Login'),
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}
