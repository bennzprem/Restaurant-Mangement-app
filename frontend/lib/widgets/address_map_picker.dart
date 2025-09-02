import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddressMapPicker extends StatefulWidget {
  final LatLng initial;
  const AddressMapPicker({super.key, required this.initial});

  @override
  State<AddressMapPicker> createState() => _AddressMapPickerState();
}

class _AddressMapPickerState extends State<AddressMapPicker> {
  LatLng? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick location')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.initial,
          initialZoom: 15,
          onTap: (tapPosition, latlng) => setState(() => selected = latlng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'restaurant_app',
          ),
          if (selected != null)
            MarkerLayer(markers: [
              Marker(
                point: selected!,
                width: 40,
                height: 40,
                child:
                    const Icon(Icons.location_on, color: Colors.red, size: 36),
              )
            ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: selected == null
                ? null
                : () => Navigator.pop(context, selected),
            child: const Text('Use this location'),
          ),
        ),
      ),
    );
  }
}

