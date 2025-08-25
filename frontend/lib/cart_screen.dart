// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // 1. Added Razorpay import

import 'api_service.dart';
import 'cart_provider.dart';
import 'auth_provider.dart';
import 'models.dart';

// 2. Added the main StatefulWidget class definition
class CartScreen extends StatefulWidget {
  final String? tableSessionId;
  const CartScreen({super.key, this.tableSessionId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Razorpay _razorpay;
  late CartProvider _cart;
  late AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initiatePayment() async {
    // Store providers in member variables before the async gap to safely use them later
    _cart = Provider.of<CartProvider>(context, listen: false);
    _auth = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();

    if (_auth.user == null) {
      showLoginPrompt(context);
      return;
    }

    try {
      final razorpayOrderId =
          await apiService.createRazorpayOrder(_cart.totalAmount);

      var options = {
        'key': 'YOUR_TEST_KEY_ID', // <-- IMPORTANT: USE YOUR TEST KEY ID HERE
        'amount': _cart.totalAmount * 100, // amount in paise
        'name': 'ByteEat',
        'order_id': razorpayOrderId,
        'description': 'Food Order Payment',
        'prefill': {'email': _auth.user?.email ?? ''}
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\₹');
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
                    // Online Delivery Logic now initiates payment
                    _initiatePayment();
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
