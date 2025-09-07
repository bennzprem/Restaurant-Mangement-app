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
import 'widgets/address_map_picker.dart';
import 'widgets/header_widget.dart';
import 'theme.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? _addressLine;
  String? _addressLine2;
  String? _city;
  String? _stateProvince;
  String? _pincode;
  String? _contactNumber;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
  }

  Future<Map<String, String>> _reverseGeocodeNominatim(LatLng pos) async {
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}');
    final res = await http.get(uri, headers: {'User-Agent': 'byteeat-app'});
    if (res.statusCode != 200) return {};
    final data = json.decode(res.body);
    final addr = (data['address'] ?? {}) as Map<String, dynamic>;
    return {
      'full': data['display_name'] ?? '',
      'road': addr['road'] ?? addr['residential'] ?? addr['pedestrian'] ?? '',
      'city': addr['city'] ?? addr['town'] ?? addr['village'] ?? '',
      'state': addr['state'] ?? '',
      'postcode': addr['postcode'] ?? '',
    };
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
        'prefill': {
          'email': _auth.user?.email ?? '',
          'contact': _contactNumber ?? ''
        },
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
        'prefill': {
          'email': _auth.user?.email ?? '',
          'contact': _contactNumber ?? ''
        },
      };
      _razorpay!.open(options);
    }
  }

  Future<void> _promptAddressThenPay() async {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController(text: _addressLine ?? '');
    final address2Controller = TextEditingController(text: _addressLine2 ?? '');
    final cityController = TextEditingController(text: _city ?? '');
    final stateController = TextEditingController(text: _stateProvince ?? '');
    final pincodeController = TextEditingController(text: _pincode ?? '');
    final phoneController = TextEditingController(text: _contactNumber ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery Details'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address line 1',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? 'Please enter a valid address'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: address2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address line 2 (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter city'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter state'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || !RegExp(r'^\d{6}$').hasMatch(v))
                                ? 'Enter 6-digit pincode'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || !RegExp(r'^\d{10}$').hasMatch(v))
                                ? 'Enter 10-digit number'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Pick on map'),
                    onPressed: () async {
                      final start = const LatLng(12.9716, 77.5946);
                      final picked = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressMapPicker(initial: start),
                        ),
                      );
                      if (picked is LatLng) {
                        final details = await _reverseGeocodeNominatim(picked);
                        if (details.isNotEmpty) {
                          addressController.text =
                              details['road'] ?? addressController.text;
                          cityController.text =
                              details['city'] ?? cityController.text;
                          stateController.text =
                              details['state'] ?? stateController.text;
                          pincodeController.text =
                              details['postcode'] ?? pincodeController.text;
                          setState(() {});
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Continue to Pay'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _addressLine = addressController.text.trim();
        _addressLine2 = address2Controller.text.trim().isEmpty
            ? null
            : address2Controller.text.trim();
        _city = cityController.text.trim();
        _stateProvince = stateController.text.trim();
        _pincode = pincodeController.text.trim();
        _contactNumber = phoneController.text.trim();
      });
      if (_prefetchedOrderId == null) {
        await _prefetchOrder();
      }
      _openCheckout();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final apiService = ApiService();

    // Use the stored member variables, NOT Provider.of(context)
    apiService.placeOrder(
      _cart.items.values.toList(),
      _cart.totalAmount,
      _auth.user!.id,
      [
        if (_addressLine != null) _addressLine,
        if (_addressLine2 != null) _addressLine2,
        if (_city != null) _city,
        if (_stateProvince != null) _stateProvince,
        if (_pincode != null) 'PIN: $_pincode',
      ].whereType<String>().join(', '),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA),
      appBar: null,
      body: Column(
        children: [
          // Fixed Header
          HeaderWidget(
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          // Main content
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Text(
                      'Your cart is empty.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(cartItem.menuItem.imageUrl),
                          ),
                          title: Text(
                            cartItem.menuItem.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            currencyFormat.format(cartItem.menuItem.price),
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () =>
                                    cart.removeSingleItem(cartItem.menuItem.id),
                              ),
                            ),
                            Text('${cartItem.quantity}'),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => cart.addItem(cartItem.menuItem),
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    currencyFormat.format(cart.totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          if (cart.items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
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
                    // Ask for address/contact, then open checkout
                    _promptAddressThenPay();
                  }
                },
                ),
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
