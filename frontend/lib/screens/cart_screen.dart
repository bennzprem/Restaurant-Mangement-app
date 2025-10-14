// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // 1. Added Razorpay import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/delivery_location_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/checkout_step.dart';
import '../widgets/address_selection_dialog.dart';
import '../widgets/order_summary_card.dart';
// Removed unused imports for order tracking UI helpers
import '../services/order_tracking_service.dart';
import '../services/temp_data_service.dart';
import '../models/models.dart';
import '../widgets/order_location_picker.dart';
import 'dart:convert';
import '../pages/takeaway_confirmation_page.dart';

// 2. Added the main StatefulWidget class definition
class CartScreen extends StatefulWidget {
  final String? tableSessionId;
  final OrderMode mode;
  const CartScreen(
      {super.key, this.tableSessionId, this.mode = OrderMode.delivery});

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
  // Takeaway pickup fields
  final TextEditingController _pickupNameController = TextEditingController();
  final TextEditingController _pickupPhoneController = TextEditingController();
  DateTime? _pickupTime; // null => ASAP
  final OrderTrackingService _orderTrackingService = OrderTrackingService();

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
    _checkForPendingOrder();
  }

  void _initializeOrderTracking() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn && authProvider.user != null) {
        await _orderTrackingService.startTracking(authProvider.user!.id);
      }
    });
  }

  // Check for pending order data and restore it
  Future<void> _checkForPendingOrder() async {
    final pendingData = await TempDataService.getPendingOrder();
    if (pendingData != null) {
      final orderData = pendingData['orderData'] as Map<String, dynamic>;
      final orderType = pendingData['orderType'] as String;

      // Show dialog to continue with the order
      if (mounted) {
        _showContinueOrderDialog(orderData, orderType);
      }
    }
  }

  // Show dialog to continue with pending order
  void _showContinueOrderDialog(
      Map<String, dynamic> orderData, String orderType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue Order'),
        content: const Text(
            'We found your previous order details. Would you like to continue with your order?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              TempDataService.clearPendingOrder();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreOrderData(orderData, orderType);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Restore order data from pending order
  void _restoreOrderData(Map<String, dynamic> orderData, String orderType) {
    // Restore cart items
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.clearCart();

    // Note: This is a simplified restoration. In a real app, you'd need to
    // fetch the full menu item details and restore them properly
    // For now, we'll just clear the pending data and let the user start fresh
    TempDataService.clearPendingOrder();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add items to your cart again.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Removed unused modal; tracking UI will be added later

  // Status helpers removed (unused after refactor)

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
    _pickupNameController.dispose();
    _pickupPhoneController.dispose();
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
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null) {
      // Save current cart data before login
      final cart = Provider.of<CartProvider>(context, listen: false);
      final orderData = {
        'cartItems': cart.items.values
            .map((item) => {
                  'menuItemId': item.menuItem.id,
                  'quantity': item.quantity,
                  'specialInstructions':
                      '', // CartItem doesn't have special instructions
                })
            .toList(),
        'mode': widget.mode.toString(),
        'savedAddress': _savedAddress,
        'pickupName': _pickupNameController.text,
        'pickupPhone': _pickupPhoneController.text,
      };
      showLoginPrompt(
        context,
        orderType: widget.mode.toString().split('.').last,
        orderData: orderData,
      );
      return;
    }

    // For delivery, require address. For takeaway, require pickup details
    if (widget.mode == OrderMode.delivery) {
      if (_savedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a delivery address first.')),
        );
        return;
      }
    } else if (widget.mode == OrderMode.takeaway) {
      if ((_pickupNameController.text).trim().isEmpty ||
          (_pickupPhoneController.text).trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Enter pickup name and phone for Takeaway.')),
        );
        return;
      }
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
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null) {
      // Save current cart data before login
      final cart = Provider.of<CartProvider>(context, listen: false);
      final orderData = {
        'cartItems': cart.items.values
            .map((item) => {
                  'menuItemId': item.menuItem.id,
                  'quantity': item.quantity,
                  'specialInstructions':
                      '', // CartItem doesn't have special instructions
                })
            .toList(),
        'mode': widget.mode.toString(),
        'savedAddress': _savedAddress,
        'pickupName': _pickupNameController.text,
        'pickupPhone': _pickupPhoneController.text,
      };
      showLoginPrompt(
        context,
        orderType: widget.mode.toString().split('.').last,
        orderData: orderData,
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

    // Build address/pickup description based on mode
    String addressString;
    Map<String, double>? coordinates;

    if (widget.mode == OrderMode.takeaway) {
      final pickupWhen =
          _pickupTime != null ? _pickupTime!.toIso8601String() : 'ASAP';
      addressString = 'TAKEAWAY | Name: ${_pickupNameController.text.trim()} | '
          'Phone: ${_pickupPhoneController.text.trim()} | Time: $pickupWhen';
    } else {
      if (locationProvider.isLocationSet &&
          locationProvider.selectedLocation != null) {
        addressString = locationProvider.fullAddress;
        coordinates = await locationProvider.getCurrentLocationCoordinates();
      } else if (_savedAddress != null) {
        addressString = _savedAddress.toString();
      } else {
        addressString = 'No address provided';
      }
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
      if (widget.mode == OrderMode.takeaway) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TakeawayConfirmationPage(
              orderId: null, // backend can return id; plugged later
              pickupName: _pickupNameController.text.trim().isEmpty
                  ? null
                  : _pickupNameController.text.trim(),
              pickupPhone: _pickupPhoneController.text.trim().isEmpty
                  ? null
                  : _pickupPhoneController.text.trim(),
              pickupTimeDisplay: _pickupTime == null
                  ? 'ASAP'
                  : _pickupTime!.toLocal().toString(),
            ),
          ),
        );
      } else {
        Navigator.of(context).pop();
        _showOrderCompletionDialog();
      }
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
        if (widget.mode == OrderMode.delivery)
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
          )
        else
          CheckoutStep(
            icon: Icons.store_mall_directory,
            title: 'Pickup details',
            subtitle: 'Provide name, phone and pickup time',
            isActive: auth.isLoggedIn,
            isCompleted: _pickupNameController.text.trim().isNotEmpty &&
                _pickupPhoneController.text.trim().isNotEmpty,
            content: auth.isLoggedIn ? _buildPickupStep(isDark) : null,
          ),
        CheckoutStep(
          icon: Icons.credit_card,
          title: 'Payment',
          subtitle: widget.mode == OrderMode.takeaway
              ? 'Ready to process payment'
              : (_savedAddress != null
                  ? 'Ready to process payment'
                  : 'Please add delivery address first'),
          isActive:
              widget.mode == OrderMode.takeaway ? true : _savedAddress != null,
          content: (widget.mode == OrderMode.takeaway || _savedAddress != null)
              ? _buildPaymentStep(isDark)
              : null,
        ),
      ],
    );
  }

  Widget _buildPickupStep(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pickupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup name',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pickupPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact phone',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.schedule, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pickupTime == null
                            ? 'Pickup time: ASAP'
                            : 'Pickup time: ${_pickupTime!.toLocal()}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final now =
                            DateTime.now().add(const Duration(minutes: 20));
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (picked != null && context.mounted) {
                          final timeOfDay = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(now),
                          );
                          if (timeOfDay != null) {
                            setState(() {
                              _pickupTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                timeOfDay.hour,
                                timeOfDay.minute,
                              );
                            });
                          }
                        }
                      },
                      child: const Text('Schedule'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() => _pickupTime = null);
                      },
                      child: const Text('ASAP'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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

void showLoginPrompt(BuildContext context,
    {String? orderType, Map<String, dynamic>? orderData}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Login Required'),
      content: const Text(
          'You need to be logged in to perform this action. Your order details will be saved.'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        ElevatedButton(
          child: const Text('Login'),
          onPressed: () async {
            Navigator.of(ctx).pop();
            // Save order data if provided
            if (orderType != null && orderData != null) {
              await TempDataService.savePendingOrder(
                orderType: orderType,
                orderData: orderData,
              );
            }
            final result = await Navigator.pushNamed(context, '/login');
            // If login was successful, the calling page should handle restoration
            if (result == true && orderType != null && orderData != null) {
              // Trigger a rebuild or callback to restore order data
              // This will be handled by the calling widget
            }
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
