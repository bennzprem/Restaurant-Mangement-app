import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'book_table_page.dart';
import 'menu_screen.dart';
import 'takeaway_page.dart';
import 'theme.dart';
import 'dine_in_page.dart';
import 'admin_dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Helper function to handle taps on the cards
  void _handleNavigation(BuildContext context, String serviceType) {
    switch (serviceType) {
      case 'Delivery':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MenuScreen()),
        );
        break;
      case 'Dine-In':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DineInPage()),
        );
        break;
      case 'Takeaway':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TakeawayPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final userName = user?.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ByteEat'),
        actions: [
          authProvider.isLoggedIn
              ? TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  icon: const Icon(Icons.person, color: AppTheme.darkTextColor),
                  label: const Text(
                    'My Profile',
                    style: TextStyle(color: AppTheme.darkTextColor),
                  ),
                )
              : TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login, color: AppTheme.darkTextColor),
                  label: const Text(
                    'Login',
                    style: TextStyle(color: AppTheme.darkTextColor),
                  ),
                ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authProvider.isLoggedIn && userName != null && userName.isNotEmpty
                  ? 'Welcome, $userName!'
                  : 'Welcome to Byteat!',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to order today?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  // vvv THIS IS THE ONLY SECTION THAT HAS BEEN ADDED vvv
                  // If the user is an admin, show the dashboard card
                  if (authProvider.isAdmin) ...[
                    _ServiceSelectionCard(
                      title: 'Admin Dashboard',
                      description: 'Manage users, items, and orders.',
                      icon: Icons.dashboard_customize,
                      onTap: () {
                        // IMPORTANT: You will need to create this page.
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardPage()));
                        print(
                            "Navigating to Admin Dashboard..."); // Placeholder
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  _ServiceSelectionCard(
                    title: 'Delivery',
                    description:
                        'Get your favorite food delivered to your door.',
                    icon: Icons.delivery_dining,
                    onTap: () => _handleNavigation(context, 'Delivery'),
                  ),
                  const SizedBox(height: 16),
                  _ServiceSelectionCard(
                    title: 'Dine-In',
                    description:
                        'Book a table and enjoy our restaurant ambiance.',
                    icon: Icons.restaurant,
                    onTap: () => _handleNavigation(context, 'Dine-In'),
                  ),
                  const SizedBox(height: 16),
                  _ServiceSelectionCard(
                    title: 'Takeaway',
                    description:
                        'Place an order online and pick it up yourself.',
                    icon: Icons.shopping_bag,
                    onTap: () => _handleNavigation(context, 'Takeaway'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A private helper widget for the selection cards
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
              Icon(icon, size: 40, color: AppTheme.primaryColor),
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
