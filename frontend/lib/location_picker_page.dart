import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'address_page.dart';
import 'models.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  latlng.LatLng _currentLocation = latlng.LatLng(12.9716, 77.5946);
  AddressDetails _addressDetails = AddressDetails();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to safely extract string values from Placemark
  String? _safeGetString(String? value) {
    try {
      return value?.isNotEmpty == true ? value : null;
    } catch (e) {

      return null;
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      _updateMapLocation(latlng.LatLng(position.latitude, position.longitude));
    } catch (e) {

    }
  }

  Future<void> _searchAndMoveCamera() async {
    if (_searchController.text.isEmpty) return;
    final query = Uri.encodeComponent(_searchController.text);
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.restaurant_app'},
      );
      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        if (results.isNotEmpty) {
          final lat = double.parse(results.first['lat']);
          final lon = double.parse(results.first['lon']);
          _updateMapLocation(latlng.LatLng(lat, lon));
        }
      }
    } catch (e) {

    }
  }

  void _updateMapLocation(latlng.LatLng position) async {
    _mapController.move(position, 15.0);
    setState(() {
      _currentLocation = position;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Get the most specific area information available with proper null checks
        String area = '';
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
          } else {
            area = 'Current Location';
          }
        } catch (e) {

          area = 'Current Location';
        }

        // THIS IS THE KEY: We create the detailed address object here with safe null handling
        _addressDetails = AddressDetails(
          houseNo: _safeGetString(place.name) ??
              _safeGetString(place.subThoroughfare) ??
              '',
          area: area,
          city: _safeGetString(place.locality) ??
              _safeGetString(place.subAdministrativeArea) ??
              '',
          state: _safeGetString(place.administrativeArea) ?? '',
          pincode: _safeGetString(place.postalCode) ?? '',
        );
        setState(() {
          final displayArea = _addressDetails.area.isNotEmpty
              ? _addressDetails.area
              : 'Unknown Area';
          final city = _addressDetails.city.isNotEmpty
              ? _addressDetails.city
              : 'Unknown City';
          _searchController.text = "$displayArea, $city";
        });
      } else {
        // Fallback if no placemarks found
        _addressDetails = AddressDetails(
          houseNo: '',
          area: 'Current Location',
          city: 'Unknown City',
          state: '',
          pincode: '',
        );
        setState(() {
          _searchController.text = "Current Location";
        });
      }
    } catch (e) {

      // Fallback on error
      _addressDetails = AddressDetails(
        houseNo: '',
        area: 'Current Location',
        city: 'Unknown City',
        state: '',
        pincode: '',
      );
      setState(() {
        _searchController.text = "Current Location";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: 'Search for area, street name...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndMoveCamera,
                    ),
                  ),
                  onSubmitted: (value) => _searchAndMoveCamera(),
                  onTap: () {
                    if (_searchController.text.contains('Resolving')) {
                      _searchController.clear();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.blue),
                  title: const Text('Use my current location'),
                  onTap: _determinePosition,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
                onTap: (tapPosition, point) => _updateMapLocation(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.restaurant_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              child: const Text('Confirm Location & Proceed'),
              onPressed: () {
                // We pass the fully populated address object to the next page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddressPage(addressDetails: _addressDetails),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*/ lib/location_picker_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'address_page.dart';
import 'models.dart'; // Ensure AddressDetails is here

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  latlng.LatLng _currentLocation = latlng.LatLng(12.9716, 77.5946);
  AddressDetails _addressDetails = AddressDetails();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    // ... (This function remains unchanged from the working version)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      _updateMapLocation(latlng.LatLng(position.latitude, position.longitude));
    } catch (e) {

    }
  }

  Future<void> _searchAndMoveCamera() async {
    // ... (This function remains unchanged from the working version)
    if (_searchController.text.isEmpty) return;
    final query = Uri.encodeComponent(_searchController.text);
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.restaurant_app'},
      );
      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        if (results.isNotEmpty) {
          final lat = double.parse(results.first['lat']);
          final lon = double.parse(results.first['lon']);
          _updateMapLocation(latlng.LatLng(lat, lon));
        }
      }
    } catch (e) {

    }
  }

  void _updateMapLocation(latlng.LatLng position) async {
    _mapController.move(position, 15.0);
    setState(() {
      _currentLocation = position;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // THIS IS THE KEY: We create the detailed address object here
        _addressDetails = AddressDetails(
          houseNo: place.name ?? '',
          area: place.street ?? '',
          city: place.locality ?? '',
          state: place.administrativeArea ?? '',
          pincode: place.postalCode ?? '',
        );
        setState(() {
          // This updates the text field to show the user what was found
          _searchController.text =
              "${_addressDetails.area}, ${_addressDetails.city}";
        });
      }
    } catch (e) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: 'Search for area, street name...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAndMoveCamera,
                    ),
                  ),
                  onSubmitted: (value) => _searchAndMoveCamera(),
                  onTap: () {
                    if (_searchController.text.contains('Resolving')) {
                      _searchController.clear();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.blue),
                  title: const Text('Use my current location'),
                  onTap: _determinePosition,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
                onTap: (tapPosition, point) => _updateMapLocation(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.restaurant_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              child: const Text('Confirm Location & Proceed'),
              onPressed: () {
                // We pass the fully populated address object to the next page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddressPage(addressDetails: _addressDetails),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}*/
