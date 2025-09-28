import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart';
import 'delivery_details_form.dart';

class LocationSelectionPopup extends StatefulWidget {
  const LocationSelectionPopup({super.key});

  @override
  _LocationSelectionPopupState createState() => _LocationSelectionPopupState();
}

class _LocationSelectionPopupState extends State<LocationSelectionPopup> {
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location services are disabled. Please enable them to use this feature.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission denied. Please enable location access.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location permission permanently denied. Please enable in settings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting your current location...'),
          duration: Duration(seconds: 2),
        ),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateMapLocation(latlng.LatLng(position.latitude, position.longitude));
    } catch (e) {
      print("Error getting current position: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      print("Error searching: $e");
    }
  }

  void _updateMapLocation(latlng.LatLng position) async {
    _mapController.move(position, 15.0);
    setState(() {
      _currentLocation = position;
    });

    try {
      // Try multiple geocoding approaches for better results
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Extract address components with better fallbacks
        String houseNo = place.name ?? place.subThoroughfare ?? '';
        String area =
            place.thoroughfare ?? place.subLocality ?? place.locality ?? '';
        String city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            '';
        String state = place.administrativeArea ?? place.country ?? '';
        String pincode = place.postalCode ?? '';

        print("Initial geocoding data:");
        print("  thoroughfare: ${place.thoroughfare}");
        print("  subLocality: ${place.subLocality}");
        print("  locality: ${place.locality}");
        print("  subAdministrativeArea: ${place.subAdministrativeArea}");
        print("  administrativeArea: ${place.administrativeArea}");
        print("  postalCode: ${place.postalCode}");
        print("  name: ${place.name}");
        print("  subThoroughfare: ${place.subThoroughfare}");
        print("  Initial area: $area");

        // Always try Nominatim for better area name resolution
        try {
          final response = await http.get(
            Uri.parse(
                'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1&zoom=18'),
            headers: {'User-Agent': 'com.example.restaurant_app'},
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final address = data['address'] ?? {};

            print("Nominatim response data:");
            print("  Full address: $address");
            print("  Road: ${address['road']}");
            print("  Suburb: ${address['suburb']}");
            print("  Neighbourhood: ${address['neighbourhood']}");
            print("  Quarter: ${address['quarter']}");
            print("  Hamlet: ${address['hamlet']}");
            print("  Village: ${address['village']}");
            print("  City: ${address['city']}");
            print("  Town: ${address['town']}");

            // Try multiple approaches to get a good area name
            List<String> areaCandidates = [
              address['road'],
              address['suburb'],
              address['neighbourhood'],
              address['quarter'],
              address['hamlet'],
              address['village'],
              address['city_district'],
              address['county'],
              address['city'],
              address['town'],
            ]
                .where((item) => item != null && item.toString().isNotEmpty)
                .cast<String>()
                .toList();

            print("Area candidates: $areaCandidates");

            // Find the best area name (prefer shorter, more specific names)
            String? bestArea;
            for (String candidate in areaCandidates) {
              if (candidate.length > 2 && candidate.length < 50) {
                bestArea = candidate;
                break; // Take the first good candidate
              }
            }

            if (bestArea != null) {
              area = bestArea;
              print("Using best area: $bestArea");
            } else {
              print("No suitable area found in Nominatim data");
            }

            // Also get better city and state data
            if (city.isEmpty || city == 'Unknown City') {
              city = address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['county'] ??
                  city;
            }
            if (state.isEmpty || state == 'Unknown State') {
              state = address['state'] ?? address['region'] ?? state;
            }
            if (pincode.isEmpty) {
              pincode = address['postcode'] ?? pincode;
            }

            print("Nominatim data: area=$area, city=$city, state=$state");
          }
        } catch (e) {
          print("Nominatim geocoding error: $e");
        }

        // Ensure we have a meaningful area name
        if (area.isEmpty || area == 'Selected Area' || area.length < 3) {
          // Try to create a meaningful area name from available data
          if (city.isNotEmpty && city != 'Bengaluru') {
            area = 'Near $city';
          } else if (state.isNotEmpty && state != 'Karnataka') {
            area = 'Near $state';
          } else {
            // Use coordinates as a last resort
            area =
                'Location (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})';
          }
          print("Using fallback area: $area");
        }

        _addressDetails = AddressDetails(
          houseNo: houseNo,
          area: area,
          city: city.isNotEmpty ? city : 'Bengaluru',
          state: state.isNotEmpty ? state : 'Karnataka',
          pincode: pincode,
        );

        setState(() {
          // Create a more descriptive search text
          List<String> addressParts = [];
          if (area.isNotEmpty && area != 'Selected Area')
            addressParts.add(area);
          if (city.isNotEmpty && city != 'Bengaluru') addressParts.add(city);
          if (state.isNotEmpty && state != 'Karnataka') addressParts.add(state);

          _searchController.text = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Selected Location, Bengaluru';
        });
      } else {
        // Fallback to a more generic approach using coordinates
        _addressDetails = AddressDetails(
          houseNo: '',
          area: 'Selected Area',
          city: 'Bengaluru',
          state: 'Karnataka',
          pincode: '',
        );
        setState(() {
          _searchController.text = "Selected Location, Bengaluru";
        });
      }
    } catch (e) {
      print("Geocoding error: $e");
      // Fallback for geocoding errors
      _addressDetails = AddressDetails(
        houseNo: '',
        area: 'Selected Area',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '',
      );
      setState(() {
        _searchController.text = "Selected Location, Bengaluru";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Select Delivery Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),

            // Search Bar
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
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.my_location, color: Colors.blue),
                    title: const Text('Use my current location'),
                    onTap: _determinePosition,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) => _updateMapLocation(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
              ),
            ),

            // Selected Location Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_addressDetails.area}, ${_addressDetails.city}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Proceed Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Proceed with Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DeliveryDetailsForm(
                        addressDetails: _addressDetails,
                        latitude: _currentLocation.latitude,
                        longitude: _currentLocation.longitude,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
