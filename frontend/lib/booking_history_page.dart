import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'models.dart';
import 'theme.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late Future<List<Reservation>> _reservationsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Fetch reservations when the page loads
    _loadReservations();
  }

  void _loadReservations() {
    // Get the auth token from the provider to make an authenticated request
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token != null) {
      setState(() {
        _reservationsFuture = _apiService.getReservations(token);
      });
    } else {
      // Handle case where user is not logged in or token is unavailable
      // This creates a Future that completes with an error.
      setState(() {
        _reservationsFuture = Future.error('You are not logged in.');
      });
    }
  }

  Future<void> _handleCancelReservation(String reservationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) return;

    // Show a confirmation dialog before cancelling
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.cancelReservation(
          reservationId: reservationId,
          authToken: token,
        );
        // Refresh the list after cancellation
        _loadReservations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reservations')),
      body: FutureBuilder<List<Reservation>>(
        future: _reservationsFuture,
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Error State ---
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // --- Empty State ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no reservations.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          // --- Success State ---
          final reservations = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final booking = reservations[index];
              final bool isUpcoming = booking.reservationTime.isAfter(
                DateTime.now(),
              );
              final bool canCancel =
                  isUpcoming && booking.status == 'confirmed';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Table ${booking.table.tableNumber}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Chip(
                            label: Text(
                              booking.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: booking.status == 'confirmed'
                                ? AppTheme.accentColor
                                : Colors.grey,
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        '${DateFormat('EEEE, dd MMM yyyy').format(booking.reservationTime)} at ${DateFormat('h:mm a').format(booking.reservationTime)}',
                      ),
                      const SizedBox(height: 8),
                      Text('Party of ${booking.partySize}'),
                      if (booking.specialOccasion != 'None')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Occasion: ${booking.specialOccasion}'),
                        ),
                      if (canCancel)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _handleCancelReservation(booking.id),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel Booking'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
