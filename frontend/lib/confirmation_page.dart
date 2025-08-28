import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'models.dart' as app_models;
import 'theme.dart';

class ConfirmationPage extends StatefulWidget {
  final int partySize;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final app_models.Table selectedTable;

  // Remove the initialSpecialOccasion from the constructor
  const ConfirmationPage({
    super.key,
    required this.partySize,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.selectedTable,
  });

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  // Add state variables for the occasion and add-ons
  String _specialOccasion = 'None';
  bool _addCake = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _confirmAndBook() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeFormat = DateFormat("h:mm a");
      final parsedTime = timeFormat.parse(widget.selectedTimeSlot);
      final reservationDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      await _apiService.createReservation(
        tableId: widget.selectedTable.id,
        reservationTime: reservationDateTime.toIso8601String(),
        partySize: widget.partySize,
        specialOccasion: _specialOccasion, // Use the state variable
        addOnsRequested: (_specialOccasion != 'None') ? _addCake : false,
        authToken: token,
      );

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reservation Confirmed!'),
          content: const Text(
            'Your booking is confirmed. You can view it in your profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking table: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Your Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card (Unchanged)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, dd MMM yyyy',
                        ).format(widget.selectedDate),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.selectedTimeSlot,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Sriracha, Nagawara, Bangalore'),
                      const Spacer(),
                      const Icon(Icons.people_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('for ${widget.partySize} guests'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- NEW: Special Occasion Section ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Any special occasion?",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _specialOccasion,
                    items:
                        ['None', 'Birthday', 'Anniversary', 'Business Meeting']
                            .map(
                              (occasion) => DropdownMenuItem(
                                value: occasion,
                                child: Text(occasion),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _specialOccasion = value);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_specialOccasion != 'None')
                    CheckboxListTile(
                      title: Text(
                        'Book a celebration cake for your $_specialOccasion?',
                      ),
                      subtitle: const Text(
                        'A team member will contact you for details.',
                      ),
                      value: _addCake,
                      onChanged: (newValue) {
                        setState(() => _addCake = newValue!);
                      },
                      activeColor: AppTheme.accentColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading ? null : _confirmAndBook,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Book your table for Free'),
          ),
        ),
      ),
    );
  }
}
