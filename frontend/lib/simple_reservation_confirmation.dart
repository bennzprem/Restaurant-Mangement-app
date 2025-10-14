import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';

class SimpleReservationConfirmation extends StatefulWidget {
  final String tableNumber;
  final String date;
  final String time;
  final int partySize;
  final String specialOccasion;

  const SimpleReservationConfirmation({
    super.key,
    required this.tableNumber,
    required this.date,
    required this.time,
    required this.partySize,
    required this.specialOccasion,
  });

  @override
  State<SimpleReservationConfirmation> createState() =>
      _SimpleReservationConfirmationState();
}

class _SimpleReservationConfirmationState
    extends State<SimpleReservationConfirmation> {
  @override
  void initState() {
    super.initState();
    _saveReservation();
  }

  Future<void> _saveReservation() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();

      if (authProvider.accessToken == null) {

        return;
      }

      await apiService.createSimpleReservation(
        tableNumber: widget.tableNumber,
        date: widget.date,
        time: widget.time,
        partySize: widget.partySize,
        specialOccasion: widget.specialOccasion,
        authToken: authProvider.accessToken!,
      );

    } catch (e) {

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save reservation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              // Success Message
              Text(
                'Table Reserved!',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF33691E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Your table has been successfully reserved.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Reservation Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservation Details',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF33691E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.table_restaurant,
                      label: 'Table',
                      value: 'Table ${widget.tableNumber}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('EEEE, MMMM d, yyyy')
                          .format(DateTime.parse(widget.date)),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: widget.time,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.people,
                      label: 'Party Size',
                      value:
                          '${widget.partySize} ${widget.partySize == 1 ? 'Guest' : 'Guests'}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.celebration,
                      label: 'Special Occasion',
                      value: widget.specialOccasion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33691E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF33691E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF33691E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
