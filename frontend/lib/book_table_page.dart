import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'confirmation_page.dart'; // Make sure this is imported
import 'models.dart' as app_models;
import 'theme.dart';

class BookTablePage extends StatefulWidget {
  const BookTablePage({super.key});

  @override
  State<BookTablePage> createState() => _BookTablePageState();
}

class _BookTablePageState extends State<BookTablePage> {
  // --- UI State ---
  int _partySize = 2;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  final String _specialOccasion =
      'None'; // This can be passed to the confirmation page

  // --- API State ---
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Hardcoded time slots for the UI
  final List<String> _timeSlots = [
    '07:00 PM',
    '07:15 PM',
    '07:30 PM',
    '07:45 PM',
    '08:00 PM',
    '08:15 PM',
    '08:30 PM',
    '08:45 PM',
    '09:00 PM',
    '09:15 PM',
    '09:30 PM',
    '09:45 PM',
    '10:00 PM',
  ];

  // --- UPDATED API Method ---
  void _checkAvailabilityAndProceed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a table.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tables = await _apiService.fetchAvailableTables(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        time: _selectedTimeSlot!,
        partySize: _partySize,
      );

      if (tables.isEmpty) {
        // If no tables are found, show a message and stay on the page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sorry, no tables available for the selected criteria.',
            ),
          ),
        );
      } else {
        // If tables ARE available, pick the first one and navigate to confirmation
        final bestTable = tables.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              partySize: _partySize,
              selectedDate: _selectedDate,
              selectedTimeSlot: _selectedTimeSlot!,
              selectedTable: bestTable,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book a table'),
            Text(
              'Bengaluru, Karnataka',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildGuestSelector(),
              const SizedBox(height: 24),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildTimeSelector(),
              const SizedBox(height: 80), // Space for the floating button
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: (_selectedTimeSlot != null && !_isLoading)
                ? _checkAvailabilityAndProceed
                : null,
            child: const Text('Check Availability & Proceed'),
          ),
        ),
      ),
    );
  }

  // --- UI Builder Widgets (Guest, Date, and Time selectors remain the same) ---
  Widget _buildGuestSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number of guest(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(10, (index) {
                  final guestCount = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$guestCount'),
                      selectedColor: AppTheme.primaryColor,
                      selected: _partySize == guestCount,
                      onSelected: (isSelected) {
                        if (isSelected) {
                          setState(() => _partySize = guestCount);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When are you visiting?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(14, (index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate.day == date.day &&
                      _selectedDate.month == date.month &&
                      _selectedDate.year == date.year;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              index == 0
                                  ? 'Today'
                                  : DateFormat('EEE').format(date),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      child: ExpansionTile(
        title: Text(
          'Select the time of day',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        leading: const Icon(Icons.dinner_dining_outlined),
        subtitle: const Text('Dinner'),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _timeSlots.map((time) {
                final now = DateTime.now();
                final isToday = _selectedDate.year == now.year &&
                    _selectedDate.month == now.month &&
                    _selectedDate.day == now.day;

                bool isPast = false;
                if (isToday) {
                  final timeFormat = DateFormat("h:mm a");
                  final slotTime = timeFormat.parse(time);
                  final slotDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    slotTime.hour,
                    slotTime.minute,
                  );
                  isPast = slotDateTime.isBefore(now);
                }

                return ChoiceChip(
                  label: Text(time),
                  labelStyle: TextStyle(
                    color: isPast ? Colors.grey.shade600 : null,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                  selected: _selectedTimeSlot == time,
                  selectedColor: AppTheme.primaryColor,
                  onSelected: isPast
                      ? null
                      : (isSelected) {
                          setState(() {
                            _selectedTimeSlot = isSelected ? time : null;
                          });
                        },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
