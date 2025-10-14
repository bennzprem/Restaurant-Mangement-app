import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../auth_provider.dart';
import '../models.dart';

class AddressSelectionWidget extends StatefulWidget {
  final Function(SavedAddress?) onAddressSelected;
  final bool showAddNewOption;

  const AddressSelectionWidget({
    super.key,
    required this.onAddressSelected,
    this.showAddNewOption = true,
  });

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  List<SavedAddress> _savedAddresses = [];
  SavedAddress? _selectedAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      final addresses =
          await ApiService().getSavedAddresses(authProvider.user!.id);
      setState(() {
        _savedAddresses = addresses;
        _selectedAddress = addresses.isNotEmpty ? addresses.first : null;
        _isLoading = false;
      });

      // Notify parent of selected address
      widget.onAddressSelected(_selectedAddress);
    } catch (e) {

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_savedAddresses.isEmpty) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.location_off, color: Colors.orange.shade700, size: 48),
              const SizedBox(height: 12),
              Text(
                'No Saved Addresses',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add an address to your profile for faster checkout',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Delivery Address',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
        ),
        const SizedBox(height: 12),
        ...(_savedAddresses.map((address) => _buildAddressCard(address))),
      ],
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    final isSelected = _selectedAddress?.id == address.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: isSelected ? Colors.green.shade50 : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = address;
          });
          widget.onAddressSelected(address);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<SavedAddress>(
                value: address,
                groupValue: _selectedAddress,
                onChanged: (value) {
                  setState(() {
                    _selectedAddress = value;
                  });
                  widget.onAddressSelected(value);
                },
                activeColor: Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.green.shade700 : null,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (address.contactName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${address.contactName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (address.contactPhone != null) ...[
                      Text(
                        'Phone: ${address.contactPhone}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

