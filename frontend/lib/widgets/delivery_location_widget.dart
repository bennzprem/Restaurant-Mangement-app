import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/delivery_location_provider.dart';
import '../location_picker_with_coordinates.dart';
import '../models.dart';
import '../theme.dart';

class DeliveryLocationWidget extends StatelessWidget {
  const DeliveryLocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryLocationProvider>(
      builder: (context, locationProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: locationProvider.isLocationSet
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showLocationPicker(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: locationProvider.isLocationSet
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: locationProvider.isLocationSet
                            ? AppTheme.primaryColor
                            : Colors.grey[600],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locationProvider.isLocationSet
                                ? 'Deliver to'
                                : 'Select delivery location',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            locationProvider.formattedLocation,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: locationProvider.isLocationSet
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: locationProvider.isLocationSet
                                  ? Colors.black87
                                  : Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (locationProvider.isLocationSet &&
                              locationProvider.deliveryTime != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 12, color: Colors.green[600]),
                                const SizedBox(width: 3),
                                Text(
                                  locationProvider.deliveryTime!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (locationProvider.deliveryFee != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.local_shipping,
                                      size: 12, color: Colors.orange[600]),
                                  const SizedBox(width: 3),
                                  Text(
                                    '₹${locationProvider.deliveryFee!.toStringAsFixed(0)} delivery',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLocationPicker(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerWithCoordinates(),
      ),
    );

    if (result != null) {
      final address = result['address'] as AddressDetails;
      final latitude = result['latitude'] as double;
      final longitude = result['longitude'] as double;

      final locationProvider =
          Provider.of<DeliveryLocationProvider>(context, listen: false);
      locationProvider.setDeliveryLocation(address,
          latitude: latitude, longitude: longitude);
    }
  }
}
