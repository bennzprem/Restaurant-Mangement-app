// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'cart_provider.dart';
//import 'order_tracking_screen.dart';
import 'auth_provider.dart';
//import 'theme.dart';
import 'address_page.dart';
import 'location_picker_page.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\₹');

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
                          backgroundImage: NetworkImage(
                            cartItem.menuItem.imageUrl,
                          ),
                        ),
                        title: Text(cartItem.menuItem.name),
                        subtitle: Text(
                          currencyFormat.format(cartItem.menuItem.price),
                        ),
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
                  Text(
                    'Total:',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    currencyFormat.format(cart.totalAmount),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          if (cart.items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                child: const Text('Place Order'),
                // Find the "Place Order" ElevatedButton and update its onPressed
                // In CartScreen, inside the ElevatedButton...
                /*onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final cart = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );

                  if (authProvider.isLoggedIn) {
                    try {
                      // This is the actual order placement logic
                      final result = await ApiService().placeOrder(
                        cart.items.values.toList(),
                        cart.totalAmount,
                        authProvider.user!.id, // Pass the user ID
                      );
                      final orderId = result['order_id'];
                      cart.clear();
                      // Navigate to tracking screen (if you have one)
                      // For now, just show a success message and pop
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order #${orderId} placed successfully!',
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error placing order: $e')),
                      );
                    }
                  } else {
                    showLoginPrompt(context);
                  }
                },*/
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  if (authProvider.isLoggedIn) {
                    // Navigate to the new location picker page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LocationPickerPage(),
                      ),
                    );
                  } else {
                    showLoginPrompt(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
// Add this function at the bottom of lib/menu_screen.dart

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
            Navigator.of(ctx).pop(); // Close the dialog
            Navigator.pushNamed(context, '/login'); // Go to login page
          },
        ),
      ],
    ),
  );
}
