// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // 1. Added Razorpay import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'cart_provider.dart';
import 'auth_provider.dart';
import 'widgets/address_map_picker.dart';
import 'widgets/header_widget.dart';
import 'widgets/checkout_step.dart';
import 'widgets/order_summary_card.dart';
import 'models.dart';
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
  AddressDetails? _savedAddress;

  // Helper method to calculate total amount including fees
  double get _totalAmountWithFees {
    final deliveryFee = 41.0;
    final gstAndCharges = 74.69;
    return _cart.totalAmount + deliveryFee + gstAndCharges;
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final addressJson = prefs.getString('address_${auth.user!.id}');
      if (addressJson != null) {
        final addressData = jsonDecode(addressJson);
        setState(() {
          _savedAddress = AddressDetails(
            houseNo: addressData['houseNo'] ?? '',
            area: addressData['area'] ?? '',
            city: addressData['city'] ?? '',
            state: addressData['state'] ?? '',
            pincode: addressData['pincode'] ?? '',
          );
        });
      }
    }
  }

  Future<void> _saveAddress(AddressDetails address) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final addressJson = jsonEncode({
        'houseNo': address.houseNo,
        'area': address.area,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
      });
      await prefs.setString('address_${auth.user!.id}', addressJson);
      setState(() {
        _savedAddress = address;
      });
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
      final totalAmount = _totalAmountWithFees;

      final orderId = await apiService.createRazorpayOrder(totalAmount);
      setState(() {
        _prefetchedOrderId = orderId;
        _prefetchedAmountPaise = (totalAmount * 100).round();
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

    if (_savedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address first.')),
      );
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
            child: const Text('Add Address'),
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

      // Save the address for future use
      final addressDetails = AddressDetails(
        houseNo: _addressLine ?? '',
        area: _addressLine2 ?? '',
        city: _city ?? '',
        state: _stateProvince ?? '',
        pincode: _pincode ?? '',
      );
      await _saveAddress(addressDetails);

      if (_prefetchedOrderId == null) {
        await _prefetchOrder();
      }
      _openCheckout();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final apiService = ApiService();

    // Use the saved address
    final addressString = _savedAddress != null
        ? _savedAddress.toString()
        : 'No address provided';

    // Use the stored member variables, NOT Provider.of(context)
    apiService.placeOrder(
      _cart.items.values.toList(),
      _totalAmountWithFees,
      _auth.user!.id,
      addressString,
    );

    _cart.clearCart();

    if (mounted) {
      Navigator.of(context).pop();
      _showOrderCompletionDialog();
    }
  }

  void _showOrderCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return OrderCompletionDialog();
      },
    );
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
    final bool isTableMode = widget.tableSessionId != null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA),
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
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Desktop layout - Row with checkout steps and order summary
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Checkout Steps (2/3 width)
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: _buildCheckoutSteps(isDark, isTableMode),
                              ),
                            ),
                            // Right side - Order Summary (1/3 width)
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                child: OrderSummaryCard(
                                  onProceedToPay: () {
                                    if (isTableMode) {
                                      // Table Mode Logic
                                      Provider.of<CartProvider>(context,
                                              listen: false)
                                          .clearCart();
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Items sent to the kitchen!')),
                                      );
                                    } else {
                                      // Use saved address for payment
                                      _openCheckout();
                                    }
                                  },
                                  isTableMode: isTableMode,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Mobile layout - Column with stacked content
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCheckoutSteps(isDark, isTableMode),
                              OrderSummaryCard(
                                onProceedToPay: () {
                                  if (isTableMode) {
                                    // Table Mode Logic
                                    Provider.of<CartProvider>(context,
                                            listen: false)
                                        .clearCart();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Items sent to the kitchen!')),
                                    );
                                  } else {
                                    // Use saved address for payment
                                    _openCheckout();
                                  }
                                },
                                isTableMode: isTableMode,
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSteps(bool isDark, bool isTableMode) {
    final auth = Provider.of<AuthProvider>(context);

    return CheckoutStepsList(
      steps: [
        CheckoutStep(
          icon: Icons.person,
          title: auth.isLoggedIn ? 'Logged in' : 'Account',
          subtitle: auth.isLoggedIn
              ? 'Welcome back! You are ready to place your order.'
              : 'To place your order now, log in to your existing account or sign up.',
          isActive: true,
          isCompleted: auth.isLoggedIn,
          content: auth.isLoggedIn
              ? _buildLoggedInUserStep(auth, isDark)
              : _buildAccountStep(isDark),
        ),
        CheckoutStep(
          icon: Icons.location_on,
          title: 'Add a delivery address',
          subtitle: auth.isLoggedIn
              ? (_savedAddress != null
                  ? 'Address added successfully'
                  : 'You seem to be in the new location')
              : 'Please log in first to add delivery address',
          isActive: auth.isLoggedIn,
          isCompleted: _savedAddress != null,
          content: auth.isLoggedIn ? _buildDeliveryAddressStep(isDark) : null,
        ),
        CheckoutStep(
          icon: Icons.credit_card,
          title: 'Payment',
          subtitle: _savedAddress != null
              ? 'Ready to process payment'
              : 'Please add delivery address first',
          isActive: _savedAddress != null,
          content: _savedAddress != null ? _buildPaymentStep(isDark) : null,
        ),
      ],
    );
  }

  Widget _buildAccountStep(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                foregroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Have an account? LOG IN',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'New to ByteEat? SIGN UP',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInUserStep(AuthProvider auth, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${auth.user?.name ?? 'User'} | ${auth.user?.email ?? 'No email'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to place your order',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              auth.signOut();
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressStep(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          if (_savedAddress != null) ...[
            // Show existing address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _savedAddress.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _promptAddressThenPay();
                        },
                        icon: Icon(
                          Icons.edit,
                          color: const Color(0xFF4CAF50),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // No saved address - show add new address card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_location_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Adugodi, Bengaluru, Karnataka, India',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _promptAddressThenPay();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF4CAF50), width: 2),
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ADD NEW',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStep(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pay securely with Razorpay',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _openCheckout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'PAY NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
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

class OrderCompletionDialog extends StatefulWidget {
  const OrderCompletionDialog({super.key});

  @override
  State<OrderCompletionDialog> createState() => _OrderCompletionDialogState();
}

class _OrderCompletionDialogState extends State<OrderCompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animations
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start scale animation
    _scaleController.forward();

    // Wait a bit then start check animation
    await Future.delayed(const Duration(milliseconds: 200));
    _checkController.forward();

    // Wait a bit then start fade animation
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    // Auto close and redirect after 3 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    _redirectToHome();
  }

  void _redirectToHome() {
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated checkmark circle
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: CheckmarkPainter(_checkAnimation.value),
                          size: const Size(100, 100),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Order completed text
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'Order Completed!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your delicious meal is being prepared\nand will be delivered soon!',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Loading indicator
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Redirecting to home...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = ui.Path();

    // Start point of checkmark
    final startX = size.width * 0.25;
    final startY = size.height * 0.5;

    // Middle point of checkmark
    final middleX = size.width * 0.45;
    final middleY = size.height * 0.65;

    // End point of checkmark
    final endX = size.width * 0.75;
    final endY = size.height * 0.35;

    if (progress <= 0.5) {
      // Draw first part of checkmark (vertical line)
      final currentProgress = progress * 2;
      final currentY = startY + (middleY - startY) * currentProgress;

      path.moveTo(startX, startY);
      path.lineTo(middleX, currentY);
    } else {
      // Draw first part completely
      path.moveTo(startX, startY);
      path.lineTo(middleX, middleY);

      // Draw second part of checkmark (diagonal line)
      final currentProgress = (progress - 0.5) * 2;
      final currentX = middleX + (endX - middleX) * currentProgress;
      final currentY = middleY + (endY - middleY) * currentProgress;

      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
