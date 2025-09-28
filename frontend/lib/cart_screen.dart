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
import 'providers/delivery_location_provider.dart';
import 'widgets/header_widget.dart';
import 'widgets/checkout_step.dart';
import 'widgets/address_selection_dialog.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/order_tracking_button.dart';
import 'widgets/order_status_modal.dart';
import 'services/order_tracking_service.dart';
import 'models.dart';
import 'order_location_picker.dart';
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
  String? _prefetchedOrderId;
  int _prefetchedAmountPaise = 0;
  bool _isPrefetching = false;
  String? _contactNumber;
  AddressDetails? _savedAddress;
  final OrderTrackingService _orderTrackingService = OrderTrackingService();
  bool _isTrackingInitialized = false;

  // Helper method to calculate total amount including fees
  double _getTotalAmountWithFees(CartProvider cart) {
    final deliveryFee = 41.0;
    final gstAndCharges = 74.69;
    return cart.totalAmount + deliveryFee + gstAndCharges;
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
    _initializeOrderTracking();
  }

  void _initializeOrderTracking() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn && authProvider.user != null) {
        await _orderTrackingService.startTracking(authProvider.user!.id);
        setState(() {
          _isTrackingInitialized = true;
        });
      }
    });
  }

  void _showOrderTrackingModal() {
    final activeOrders = _orderTrackingService.activeOrders;
    if (activeOrders.isEmpty) return;

    // Show the first active order (you can modify this to show a list)
    final order = activeOrders.first;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Order details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.attach_money,
                      'Total Amount',
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.location_on,
                      'Delivery Address',
                      order.deliveryAddress,
                      Colors.blue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // You can add more actions here like calling restaurant
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Track Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Colors.orange;
      case 'ready for pickup':
        return Colors.blue;
      case 'out for delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Icons.restaurant;
      case 'ready for pickup':
        return Icons.store;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadSavedAddress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      try {
        // Try to get default address from API
        final defaultAddress =
            await ApiService().getDefaultAddress(auth.user!.id);
        if (defaultAddress != null) {
          setState(() {
            _savedAddress = defaultAddress.toAddressDetails();
          });
        }
      } catch (e) {
        print('Error loading saved address: $e');
        // Fallback to SharedPreferences for backward compatibility
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
  }

  @override
  void dispose() {
    _orderTrackingService.stopTracking();
    if (!kIsWeb) {
      _razorpay?.clear();
    }
    super.dispose();
  }

  Future<void> _prefetchOrder() async {
    if (_isPrefetching) return;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null || cart.items.isEmpty) return;
    _isPrefetching = true;
    try {
      final apiService = ApiService();
      final totalAmount = _getTotalAmountWithFees(cart);

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
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null) {
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
          'email': auth.user?.email ?? '',
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
          'email': auth.user?.email ?? '',
          'contact': _contactNumber ?? ''
        },
      };
      _razorpay!.open(options);
    }
  }

  void _proceedToPayment() {
    // providers
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null) {
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
          'email': auth.user?.email ?? '',
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
          'email': auth.user?.email ?? '',
          'contact': _contactNumber ?? ''
        },
      };
      _razorpay!.open(options);
    }
  }

  Future<void> _promptAddressThenPay() async {
    // Check if delivery location is already set
    final locationProvider =
        Provider.of<DeliveryLocationProvider>(context, listen: false);
    if (locationProvider.isLocationSet &&
        locationProvider.selectedLocation != null) {
      // Use the selected delivery location - proceed directly to payment
      _proceedToPayment();
      return;
    }

    // Check if user has saved addresses
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final savedAddresses =
            await ApiService().getSavedAddresses(authProvider.user!.id);

        if (savedAddresses.isNotEmpty) {
          // Show address selection dialog
          await _showAddressSelectionDialog();
          return;
        }
      }
    } catch (e) {
      print('Error loading saved addresses: $e');
    }

    // If no saved addresses, navigate to order location picker
    await _showOrderLocationPicker();
  }

  Future<void> _showAddressSelectionDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => AddressSelectionDialog(
        onAddressSelected: (address) {
          Navigator.of(context).pop(address);
        },
      ),
    );

    if (result != null) {
      if (result == 'ADD_NEW') {
        // User wants to add a new address - show delivery form
        await _showDeliveryForm();
      } else if (result is SavedAddress) {
        // Use the selected saved address
        setState(() {
          _savedAddress = result.toAddressDetails();
        });
        _proceedToPayment();
      }
    }
  }

  Future<void> _showDeliveryForm() async {
    // Navigate to delivery form for adding new address
    final result = await Navigator.push<AddressDetails>(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderLocationPicker(),
      ),
    );

    if (result != null) {
      // Use the address from the delivery form
      setState(() {
        _savedAddress = result;
      });
      _proceedToPayment();
    }
  }

  Future<void> _showOrderLocationPicker() async {
    // Navigate to the order location picker which will lead to delivery information page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderLocationPicker(),
      ),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final apiService = ApiService();
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider =
        Provider.of<DeliveryLocationProvider>(context, listen: false);

    // Use delivery location if available, otherwise fall back to saved address
    String addressString;
    Map<String, double>? coordinates;

    if (locationProvider.isLocationSet &&
        locationProvider.selectedLocation != null) {
      addressString = locationProvider.fullAddress;
      // Get coordinates from the location provider
      coordinates = await locationProvider.getCurrentLocationCoordinates();
    } else if (_savedAddress != null) {
      addressString = _savedAddress.toString();
    } else {
      addressString = 'No address provided';
    }

    // Use the providers directly
    apiService.placeOrder(
      cart.items.values.toList(),
      _getTotalAmountWithFees(cart),
      auth.user!.id,
      addressString,
    );

    // Save coordinates for delivery tracking
    if (coordinates != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_order_latitude', coordinates['latitude']!);
      await prefs.setDouble('last_order_longitude', coordinates['longitude']!);
      await prefs.setString('last_order_address', addressString);
    }

    cart.clearCart();

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
