// lib/user_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_app/models.dart';
import '../api_service.dart';
import '../auth_provider.dart';

// Importing the content widgets we created
import 'profile_content.dart';
import 'order_history_content.dart';
import 'reservations_content.dart';
import 'recommendation_card.dart';

import 'widgets/enhanced_chat_bot_widget.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_rounded},
    {'title': 'My Profile', 'icon': Icons.person_rounded},
    {'title': 'Order History', 'icon': Icons.history_rounded},
    {'title': 'My Reservations', 'icon': Icons.calendar_today_rounded},

    // New tabs added here
    {'title': 'Settings', 'icon': Icons.settings_rounded},
    {'title': 'Preferences', 'icon': Icons.tune_rounded},
    {'title': 'Billing', 'icon': Icons.credit_card_rounded},
    {'title': 'Help Center', 'icon': Icons.help_outline_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();
    final token = authProvider.accessToken;
    final userId = authProvider.user?.id;

    if (token != null && userId != null) {
      setState(() {
        _dashboardDataFuture = _fetchData(apiService, userId, token);
      });
    } else {
      _dashboardDataFuture = Future.value({'orders': [], 'reservations': []});
    }
  }

  Future<Map<String, dynamic>> _fetchData(
      ApiService api, String userId, String token) async {
    final results = await Future.wait([
      api.fetchOrderHistory(userId),
      api.getReservations(token),
    ]);
    return {
      'orders': results[0],
      'reservations': results[1],
    };
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_tabs[_selectedIndex]['title']),
        leading: isWideScreen
            ? null
            : Builder(
                builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer())),
      ),
      drawer: isWideScreen ? null : Drawer(child: _buildSidebar(context)),
      body: Row(
        children: [
          // Permanent sidebar for wide screens
          if (isWideScreen) _buildSidebar(context),
          // Main content area takes remaining space
          Expanded(
            child: Stack(
              children: [
                // Make content fill the available space
                Positioned.fill(child: _buildContent()),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: EnhancedChatBotWidget(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const ProfileContent(); // Using the functional widget
      case 2:
        return const OrderHistoryContent(); // Using the functional widget
      case 3:
        return const ReservationsContent(); // Using the functional widget
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.user;
                final initials = (user?.name.isNotEmpty ?? false)
                    ? user!.name
                        .trim()
                        .split(" ")
                        .map((n) => n.isNotEmpty ? n[0] : "")
                        .take(2)
                        .join()
                        .toUpperCase()
                    : "U";

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(
                              "${user!.avatarUrl!}?t=${DateTime.now().millisecondsSinceEpoch}")
                          : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.role ?? 'user',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 32),
          // Group 1: Core App Sections
          _buildTabItem(context,
              title: _tabs[0]['title'],
              icon: _tabs[0]['icon'],
              isSelected: _selectedIndex == 0, onTap: () {
            setState(() => _selectedIndex = 0);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          _buildTabItem(context,
              title: _tabs[1]['title'],
              icon: _tabs[1]['icon'],
              isSelected: _selectedIndex == 1, onTap: () {
            setState(() => _selectedIndex = 1);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          _buildTabItem(context,
              title: _tabs[2]['title'],
              icon: _tabs[2]['icon'],
              isSelected: _selectedIndex == 2, onTap: () {
            setState(() => _selectedIndex = 2);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          _buildTabItem(context,
              title: _tabs[3]['title'],
              icon: _tabs[3]['icon'],
              isSelected: _selectedIndex == 3, onTap: () {
            setState(() => _selectedIndex = 3);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          const SizedBox(height: 16), // A larger gap to separate sections
          // Group 2: Account and App Settings
          _buildTabItem(context,
              title: _tabs[4]['title'],
              icon: _tabs[4]['icon'],
              isSelected: _selectedIndex == 4, onTap: () {
            setState(() => _selectedIndex = 4);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          _buildTabItem(context,
              title: _tabs[5]['title'],
              icon: _tabs[5]['icon'],
              isSelected: _selectedIndex == 5, onTap: () {
            setState(() => _selectedIndex = 5);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          _buildTabItem(context,
              title: _tabs[6]['title'],
              icon: _tabs[6]['icon'],
              isSelected: _selectedIndex == 6, onTap: () {
            setState(() => _selectedIndex = 6);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          _buildTabItem(context,
              title: _tabs[7]['title'],
              icon: _tabs[7]['icon'],
              isSelected: _selectedIndex == 7, onTap: () {
            setState(() => _selectedIndex = 7);
            if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          }),
          const Spacer(), // Pushes the logout button to the bottom
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await context.read<AuthProvider>().signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context,
      {required String title,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    return Material(
      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Could not load dashboard data.'));
        }

        // --- FIX: Explicitly convert the lists to the correct type ---
        final List<Order> orders = List<Order>.from(snapshot.data!['orders']);
        final List<Reservation> reservations =
            List<Reservation>.from(snapshot.data!['reservations']);

        final activeOrders = orders
            .where((o) => o.status == 'Preparing' || o.status == 'Confirmed')
            .toList();
        final upcomingReservations = reservations
            .where((r) => r.reservationTime.isAfter(DateTime.now()))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 3 : 2;
            if (constraints.maxWidth < 850) crossAxisCount = 1;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDashboardHeader(
                    activeOrderCount: activeOrders.length,
                    upcomingReservationCount: upcomingReservations.length,
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    children: [
                      _buildQuickActionsCard(),
                      _buildRecentReservationsCard(upcomingReservations),
                      const RecommendationCard(),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardHeader(
      {required int activeOrderCount, required int upcomingReservationCount}) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name.split(' ')[0] ?? 'User';
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName! 🍴',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'You have $activeOrderCount active orders and $upcomingReservationCount upcoming reservations.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRecentReservationsCard(List<Reservation> reservations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Reservations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: reservations.isEmpty
                  ? const Center(child: Text('No upcoming reservations.'))
                  : ListView.builder(
                      itemCount:
                          reservations.length > 2 ? 2 : reservations.length,
                      itemBuilder: (context, index) {
                        final reservation = reservations[index];
                        return ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: Text(
                              'Table ${reservation.table.tableNumber} for ${reservation.partySize}'),
                          subtitle: Text(DateFormat.yMMMd()
                              .add_jm()
                              .format(reservation.reservationTime)),
                          dense: true,
                        );
                      }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/menu'),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Order Food'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/dine-in'),
                  icon: const Icon(Icons.table_restaurant),
                  label: const Text('Reserve Table'),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
