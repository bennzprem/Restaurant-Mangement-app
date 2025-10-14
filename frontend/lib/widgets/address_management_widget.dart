import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';

class AddressManagementWidget extends StatefulWidget {
  const AddressManagementWidget({super.key});

  @override
  State<AddressManagementWidget> createState() =>
      _AddressManagementWidgetState();
}

class _AddressManagementWidgetState extends State<AddressManagementWidget> {
  List<SavedAddress> _savedAddresses = [];
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
        _isLoading = false;
      });
    } catch (e) {

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      await ApiService().deleteAddress(authProvider.user!.id, addressId);
      await _loadSavedAddresses(); // Reload the list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      await ApiService().setDefaultAddress(authProvider.user!.id, addressId);
      await _loadSavedAddresses(); // Reload the list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default address updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating default address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Saved Addresses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                if (_savedAddresses.isNotEmpty)
                  TextButton.icon(
                    onPressed: _loadSavedAddresses,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_savedAddresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.location_off,
                        color: Colors.orange.shade700, size: 48),
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
                      'Add an address during checkout to save it here',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...(_savedAddresses.map((address) => _buildAddressCard(address))),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: address.isDefault ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      color: address.isDefault ? Colors.green.shade700 : null,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            const SizedBox(height: 8),
            Row(
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefaultAddress(address.id),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Set as Default'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(address),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(SavedAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
            'Are you sure you want to delete this address?\n\n${address.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAddress(address.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

