// lib/address_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'models.dart';
import 'order_tracking_screen.dart';

class AddressPage extends StatefulWidget {
  final AddressDetails addressDetails;
  const AddressPage({super.key, required this.addressDetails});

  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _houseController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Correctly initialize controllers with data passed to the widget
    _houseController = TextEditingController(
      text: widget.addressDetails.houseNo,
    );
    _areaController = TextEditingController(text: widget.addressDetails.area);
    _cityController = TextEditingController(text: widget.addressDetails.city);
    _pincodeController = TextEditingController(
      text: widget.addressDetails.pincode,
    );
  }

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    final finalAddress =
        '${_houseController.text}, ${_areaController.text}, ${_cityController.text}, ${_pincodeController.text}';

    try {
      final result = await ApiService().placeOrder(
        cart.items.values.toList(),
        cart.totalAmount,
        authProvider.user!.id,
        finalAddress,
      );
      final orderId = result['order_id'];
      cart.clearCart();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (ctx) => OrderTrackingScreen(orderId: orderId),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Delivery Address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Please confirm or edit your address:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _houseController,
              decoration: const InputDecoration(
                labelText: 'House No. / Building Name',
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Area / Street'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City / District'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmOrder,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Confirm & Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}

/*/ lib/address_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'models.dart';
import 'order_tracking_screen.dart';

class AddressPage extends StatefulWidget {
  final AddressDetails addressDetails;
  const AddressPage({super.key, required this.addressDetails});

  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _houseController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Correctly initialize controllers with data passed to the widget
    _houseController = TextEditingController(
      text: widget.addressDetails.houseNo,
    );
    _areaController = TextEditingController(text: widget.addressDetails.area);
    _cityController = TextEditingController(text: widget.addressDetails.city);
    _pincodeController = TextEditingController(
      text: widget.addressDetails.pincode,
    );
  }

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    final finalAddress =
        '${_houseController.text}, ${_areaController.text}, ${_cityController.text}, ${_pincodeController.text}';

    try {
      final result = await ApiService().placeOrder(
        cart.items.values.toList(),
        cart.totalAmount,
        authProvider.user!.id,
        finalAddress,
      );
      final orderId = result['order_id'];
      cart.clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (ctx) => OrderTrackingScreen(orderId: orderId),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Delivery Address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Please confirm or edit your address:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _houseController,
              decoration: const InputDecoration(
                labelText: 'House No. / Building Name',
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Area / Street'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City / District'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
              keyboardType: TextInputType.number,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter this field'
                  : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmOrder,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Confirm & Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
