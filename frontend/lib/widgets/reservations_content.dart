// lib/ch/reservations_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
// import '../theme.dart';

class ReservationsContent extends StatefulWidget {
  const ReservationsContent({super.key});

  @override
  State<ReservationsContent> createState() => _ReservationsContentState();
}

class _ReservationsContentState extends State<ReservationsContent> {
  late Future<List<Reservation>> _reservationsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token != null) {
      setState(() {
        _reservationsFuture = _apiService.getReservations(token);
      });
    } else {
      _reservationsFuture = Future.value([]);
    }
  }

  Future<void> _handleCancelReservation(String reservationId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

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
        await _apiService.cancelReservation(reservationId: reservationId, authToken: token);
        _loadReservations(); // Refresh the list
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled successfully.')),
        );
      } catch (e) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reservation>>(
      future: _reservationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('You have no reservations.', style: TextStyle(fontSize: 18, color: Colors.grey)));
        }

        final reservations = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final booking = reservations[index];
            final bool isUpcoming = booking.reservationTime.isAfter(DateTime.now());
            final bool canCancel = isUpcoming && booking.status == 'confirmed';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: booking.status == 'confirmed' ? Colors.blue.shade400 : Colors.grey,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('Date: ${DateFormat('EEEE, dd MMM yyyy').format(booking.reservationTime)}'),
                    Text('Time: ${DateFormat('h:mm a').format(booking.reservationTime)}'),
                    const SizedBox(height: 8),
                    Text('Party Size: ${booking.partySize} guests'),
                    if (canCancel)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _handleCancelReservation(booking.id),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Cancel Booking'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}