import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'models.dart';
import 'dart:math';

class DeliveryDetailsForm extends StatefulWidget {
  final AddressDetails addressDetails;
  final double latitude;
  final double longitude;

  const DeliveryDetailsForm({
    super.key,
    required this.addressDetails,
    required this.latitude,
    required this.longitude,
  });

  @override
  _DeliveryDetailsFormState createState() => _DeliveryDetailsFormState();
}

class _DeliveryDetailsFormState extends State<DeliveryDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _houseController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _deliveryInstructionsController;

  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _shouldSaveAddressToProfile = true; // Default to saving address
  String _deliveryType = 'Standard'; // Standard, Express, Scheduled

  @override
  void initState() {
    super.initState();
    // Auto-fill controllers with data from location picker
    _houseController =
        TextEditingController(text: widget.addressDetails.houseNo);
    _areaController = TextEditingController(text: widget.addressDetails.area);
    _cityController = TextEditingController(text: widget.addressDetails.city);
    _stateController = TextEditingController(text: widget.addressDetails.state);
    _pincodeController =
        TextEditingController(text: widget.addressDetails.pincode);

    // Initialize contact fields (these will be empty initially)
    _contactNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _deliveryInstructionsController = TextEditingController();

    // Try to get user's name from auth provider
    _loadUserDetails();
  }

  void _loadUserDetails() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _contactNameController.text = authProvider.user!.name;
      // Note: AppUser model doesn't have phone field, so we leave it empty for user to fill
    }
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

          // Update state if it's not already filled
          if (_stateController.text.isEmpty) {
            String? state = _safeGetString(place.administrativeArea);
            if (state != null) {
              _stateController.text = state;
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

  Future<void> _saveAddressToProfile() async {
    if (!_shouldSaveAddressToProfile)
      return; // Don't save if checkbox is unchecked

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      // Create address details from form data
      final addressDetails = AddressDetails(
        houseNo: _houseController.text,
        area: _areaController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
      );

      // Create saved address
      final savedAddress = SavedAddress.fromAddressDetails(
        id: Random().nextInt(1000000).toString(), // Generate temporary ID
        userId: authProvider.user!.id,
        address: addressDetails,
        contactName: _contactNameController.text,
        contactPhone: _contactPhoneController.text,
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

      // Don't show error to user as this is optional
    }
  }

  Future<void> _saveAddressOnly() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save address to profile
      await _saveAddressToProfile();

      // Create address details from form data
      final addressDetails = AddressDetails(
        houseNo: _houseController.text,
        area: _areaController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Return the address details to the previous screen
      Navigator.of(context).pop(addressDetails);
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

  // Helper method to safely extract string values from Placemark
  String? _safeGetString(String? value) {
    try {
      return value?.isNotEmpty == true ? value : null;
    } catch (e) {

      return null;
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Address'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Location Summary Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.addressDetails.area}, ${widget.addressDetails.city}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Coordinates: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Please complete your address details to save to your profile:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            // Address Fields
            Text(
              'Address Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _houseController,
              decoration: const InputDecoration(
                labelText: 'House No. / Building Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter house number or building name'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _areaController,
              decoration: InputDecoration(
                labelText: 'Area / Street *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
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
                  ? 'Please enter area or street name'
                  : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter city'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter state'
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact Information
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter contact name'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact phone number';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(
                labelText: 'Pincode *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin_drop),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pincode';
                }
                if (value.length != 6) {
                  return 'Please enter a valid 6-digit pincode';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Delivery Options
            Text(
              'Delivery Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _deliveryType,
              decoration: const InputDecoration(
                labelText: 'Delivery Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delivery_dining),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Standard', child: Text('Standard (30-45 mins)')),
                DropdownMenuItem(
                    value: 'Express', child: Text('Express (15-25 mins)')),
                DropdownMenuItem(
                    value: 'Scheduled', child: Text('Scheduled Delivery')),
              ],
              onChanged: (value) {
                setState(() {
                  _deliveryType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _deliveryInstructionsController,
              decoration: const InputDecoration(
                labelText: 'Delivery Instructions (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'e.g., Ring doorbell, Leave at gate, etc.',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Save Address Checkbox
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.save, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save Address to Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save this address for future orders',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: _shouldSaveAddressToProfile,
                      onChanged: (value) {
                        setState(() {
                          _shouldSaveAddressToProfile = value ?? true;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddressOnly,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Address',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
