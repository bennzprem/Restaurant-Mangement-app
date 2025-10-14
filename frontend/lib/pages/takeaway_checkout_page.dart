import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'takeaway_confirmation_page.dart';
import '../services/payment_service.dart';
import '../utils/pickup_code_generator.dart';

class TakeawayCheckoutPage extends StatefulWidget {
  final MenuItem itemJustAdded;
  const TakeawayCheckoutPage({super.key, required this.itemJustAdded});

  @override
  State<TakeawayCheckoutPage> createState() => _TakeawayCheckoutPageState();
}

class _TakeawayCheckoutPageState extends State<TakeawayCheckoutPage> {
  final _pickupNameController = TextEditingController();
  final _pickupPhoneController = TextEditingController();
  DateTime? _pickupTime;
  bool _isAsap = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    PaymentService.initialize();
  }

  @override
  void dispose() {
    _pickupNameController.dispose();
    _pickupPhoneController.dispose();
    super.dispose();
  }

  Future<void> _processOrderAfterPayment() async {
    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (cart.items.isEmpty) {
        _showErrorDialog('Cart is empty');
        return;
      }

      // Generate unique pickup code
      final pickupCode = PickupCodeGenerator.generatePickupCode();

      final addressString =
          'TAKEAWAY | Name: ${_pickupNameController.text} | Phone: ${_pickupPhoneController.text} | Time: ${_pickupTime == null ? 'ASAP' : DateFormat('MMM d, hh:mm a').format(_pickupTime!)} | Code: $pickupCode';

      final apiService = ApiService();
      final order = await apiService.placeOrder(
        cart.items.values.toList(),
        cart.totalAmount,
        auth.user?.id ?? '',
        addressString,
      );

      // Add pickup code to the order response
      order['pickup_code'] = pickupCode;

      cart.clearCart();
      await _saveActiveOrder(order);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TakeawayConfirmationPage(
              orderId: order['id'] ?? 0,
              pickupName: _pickupNameController.text,
              pickupPhone: _pickupPhoneController.text,
              pickupTimeDisplay: _pickupTime == null
                  ? 'ASAP'
                  : DateFormat('MMM d, hh:mm a').format(_pickupTime!),
              pickupCode: pickupCode,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error processing order: $e');
    }
  }

  Future<void> _saveActiveOrder(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_order', order.toString());
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectPickupTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _pickupTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _isAsap = false;
        });
      }
    }
  }

  void _proceedToPayment() async {
    if (_pickupNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your name for pickup');
      return;
    }

    if (_pickupPhoneController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final totalAmount = cart.totalAmount.toInt();

      final success = await PaymentService.processPayment(
        context: context,
        amount: totalAmount,
        orderId: 'TAKEAWAY_${DateTime.now().millisecondsSinceEpoch}',
        customerName: _pickupNameController.text,
        customerEmail: auth.user?.email ?? '',
        customerPhone: _pickupPhoneController.text,
        onSuccess: _processOrderAfterPayment,
      );

      if (success) {
        // Payment was successful, order processing will be handled by onSuccess callback

      } else {
        // Payment failed or was cancelled

      }
    } catch (e) {

      _showErrorDialog('Payment error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Takeaway Checkout'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Takeaway Mode Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.primaryColor),
                ),
                child: Text(
                  'Takeaway Order',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Order Summary
              _buildOrderSummary(cart, theme, isDark),
              const SizedBox(height: 24),

              // Pickup Details
              _buildPickupDetails(theme, isDark),
              const SizedBox(height: 24),

              // Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'Pay ₹${cart.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...cart.items.values
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuItem.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                'Qty: ${item.quantity}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(item.menuItem.price * item.quantity).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '₹${cart.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetails(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Name Field
          TextField(
            controller: _pickupNameController,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name for pickup',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // Phone Field
          TextField(
            controller: _pickupPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),

          // Pickup Time
          Text(
            'Pickup Time',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectPickupTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(_pickupTime == null
                      ? 'Select Time'
                      : DateFormat('MMM d, hh:mm a').format(_pickupTime!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isAsap = true;
                      _pickupTime = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isAsap ? theme.primaryColor : null,
                    foregroundColor:
                        _isAsap ? Colors.black : theme.primaryColor,
                  ),
                  child: const Text('ASAP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
