import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationTrackingPage extends StatefulWidget {
  final String deliveryAddress;
  final String customerName;
  final int orderId;

  const LocationTrackingPage({
    super.key,
    required this.deliveryAddress,
    required this.customerName,
    required this.orderId,
  });

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  Set<Marker> _markers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getDestinationLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateMarkers();
      });
    } catch (e) {
      _showErrorSnackBar('Error getting current location: $e');
    }
  }

  Future<void> _getDestinationLocation() async {
    try {
      List<Location> locations =
          await locationFromAddress(widget.deliveryAddress);
      if (locations.isNotEmpty) {
        setState(() {
          _destinationLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _updateMarkers();
          _loading = false;
        });
      } else {
        _showErrorSnackBar('Could not find destination location');
        setState(() => _loading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Error getting destination location: $e');
      setState(() => _loading = false);
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};

    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          infoWindow: InfoWindow(
            title: widget.customerName,
            snippet: widget.deliveryAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Fit camera to show both markers
    if (_currentLocation != null &&
        _destinationLocation != null &&
        _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _currentLocation!.latitude < _destinationLocation!.latitude
                  ? _currentLocation!.latitude
                  : _destinationLocation!.latitude,
              _currentLocation!.longitude < _destinationLocation!.longitude
                  ? _currentLocation!.longitude
                  : _destinationLocation!.longitude,
            ),
            northeast: LatLng(
              _currentLocation!.latitude > _destinationLocation!.latitude
                  ? _currentLocation!.latitude
                  : _destinationLocation!.latitude,
              _currentLocation!.longitude > _destinationLocation!.longitude
                  ? _currentLocation!.longitude
                  : _destinationLocation!.longitude,
            ),
          ),
          100.0,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId} - Location'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Order info header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer: ${widget.customerName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Delivery Address:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        widget.deliveryAddress,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: _currentLocation == null ||
                          _destinationLocation == null
                      ? const Center(
                          child: Text('Unable to load map locations'),
                        )
                      : GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            _updateMarkers();
                          },
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation ?? _destinationLocation!,
                            zoom: 15.0,
                          ),
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Refresh Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to external maps app
                            _openInExternalMaps();
                          },
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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

  void _openInExternalMaps() {
    if (_destinationLocation != null) {
      final lat = _destinationLocation!.latitude;
      final lng = _destinationLocation!.longitude;

      // You can use url_launcher package to open external maps
      // For now, we'll show a dialog with the coordinates
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Navigate to Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${widget.customerName}'),
              const SizedBox(height: 8),
              Text('Address: ${widget.deliveryAddress}'),
              const SizedBox(height: 8),
              Text('Coordinates: $lat, $lng'),
              const SizedBox(height: 8),
              Text(
                  'Google Maps URL: https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
