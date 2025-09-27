// lib/address_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'models.dart';
import 'dart:math';

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
  bool _isGettingLocation = false;

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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(
            'Location services are disabled. Please enable location services.');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError(
              'Location permissions are denied. Please enable location permissions.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
            'Location permissions are permanently denied. Please enable them in settings.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String area = '';

        // Try to get the most specific area information with safe null checks
        try {
          String? street = _safeGetString(place.street);
          String? subLocality = _safeGetString(place.subLocality);
          String? locality = _safeGetString(place.locality);
          String? administrativeArea = _safeGetString(place.administrativeArea);

          if (street != null) {
            area = street;
          } else if (subLocality != null) {
            area = subLocality;
          } else if (locality != null) {
            area = locality;
          } else if (administrativeArea != null) {
            area = administrativeArea;
          }
        } catch (e) {
          print("Error extracting area: $e");
          area = '';
        }

        if (area.isNotEmpty) {
          _areaController.text = area;

          // Also update city if it's not already filled
          if (_cityController.text.isEmpty) {
            String? city = _safeGetString(place.locality);
            if (city != null) {
              _cityController.text = city;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated: $area'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _showLocationError('Could not determine area from current location.');
        }
      } else {
        _showLocationError(
            'Could not get address information from current location.');
      }
    } catch (e) {
      _showLocationError('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper method to safely extract string values from Placemark
  String? _safeGetString(String? value) {
    try {
      return value?.isNotEmpty == true ? value : null;
    } catch (e) {
      print("Error extracting string value: $e");
      return null;
    }
  }

  Future<void> _saveAddressOnly() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save address to profile
      await _saveAddressToProfile();

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to previous screen
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddressToProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      // Create address details from form data
      final addressDetails = AddressDetails(
        houseNo: _houseController.text,
        area: _areaController.text,
        city: _cityController.text,
        pincode: _pincodeController.text,
      );

      // Create saved address
      final savedAddress = SavedAddress.fromAddressDetails(
        id: Random().nextInt(1000000).toString(), // Generate temporary ID
        userId: authProvider.user!.id,
        address: addressDetails,
        isDefault: true, // Set as default address
      );

      // Save to profile
      await ApiService().saveAddress(savedAddress);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved to your profile!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving address: $e');
      // Don't show error to user as this is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Address')),
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
              decoration: InputDecoration(
                labelText: 'Area / Street',
                suffixIcon: _isGettingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                        tooltip: 'Use current location',
                      ),
              ),
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
              onPressed: _isLoading ? null : _saveAddressOnly,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}
