import 'package:flutter/foundation.dart';
import '../models/models.dart';

class DeliveryLocationProvider extends ChangeNotifier {
  AddressDetails? _selectedLocation;
  double? _latitude;
  double? _longitude;
  String? _deliveryTime;
  double? _deliveryFee;

  // Getters
  bool get isLocationSet => _selectedLocation != null;

  AddressDetails? get selectedLocation => _selectedLocation;

  String get formattedLocation {
    if (_selectedLocation == null) {
      return 'Tap to select location';
    }
    return '${_selectedLocation!.area}, ${_selectedLocation!.city}';
  }

  String get fullAddress {
    if (_selectedLocation == null) {
      return '';
    }
    return _selectedLocation.toString();
  }

  String? get deliveryTime => _deliveryTime;

  double? get deliveryFee => _deliveryFee;

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  // Methods
  void setDeliveryLocation(
    AddressDetails address, {
    double? latitude,
    double? longitude,
  }) {
    _selectedLocation = address;
    _latitude = latitude;
    _longitude = longitude;

    // Calculate delivery time and fee based on location
    _calculateDeliveryDetails();

    notifyListeners();
  }

  void clearLocation() {
    _selectedLocation = null;
    _latitude = null;
    _longitude = null;
    _deliveryTime = null;
    _deliveryFee = null;
    notifyListeners();
  }

  Future<Map<String, double>?> getCurrentLocationCoordinates() async {
    if (_latitude != null && _longitude != null) {
      return {
        'latitude': _latitude!,
        'longitude': _longitude!,
      };
    }
    return null;
  }

  void initialize() {
    // Initialize any required data or load saved location
    // This method can be called when the provider is first created
    notifyListeners();
  }

  void _calculateDeliveryDetails() {
    if (_selectedLocation == null) return;

    // Simple delivery calculation logic
    // In a real app, this would call an API to get actual delivery time and fee

    // Mock delivery time calculation (15-45 minutes)
    final random = DateTime.now().millisecondsSinceEpoch % 30;
    _deliveryTime = '${15 + random} min';

    // Mock delivery fee calculation (₹20-₹80 based on distance)
    final feeRandom = DateTime.now().millisecondsSinceEpoch % 60;
    _deliveryFee = 20.0 + feeRandom;
  }
}
