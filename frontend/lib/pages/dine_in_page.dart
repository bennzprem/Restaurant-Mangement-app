import 'package:flutter/material.dart';
import 'book_table_page.dart'; // Import the renamed booking page
import 'order_from_table_page.dart'; // Import the new QR page
import '../utils/theme.dart';

class DineInPage extends StatelessWidget {
  const DineInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dine-In Options')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _ServiceSelectionCard(
              title: 'Order from Table',
              description:
                  'Scan a QR code at your table to view the menu and order.',
              icon: Icons.qr_code_scanner,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderFromTablePage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _ServiceSelectionCard(
              title: 'Reserve a Table',
              description: 'Book a table in advance for a future date.',
              icon: Icons.calendar_month,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookTablePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for the selection cards
// FIX: The typo '_ServiceSelection_Card' has been corrected to '_ServiceSelectionCard'
class _ServiceSelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
