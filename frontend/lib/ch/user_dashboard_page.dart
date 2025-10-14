// lib/user_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_provider.dart';
import '../services/subscription_service.dart';
import '../subscription_models.dart';

// Importing the content widgets we created
import 'profile_content.dart';
import 'order_history_content.dart';
import 'reservations_content.dart';
import 'recommendation_card.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarWidthAnimation;
  final SubscriptionService _subscriptionService = SubscriptionService();
  UserSubscription? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Initialize sidebar animation
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sidebarWidthAnimation = Tween<double>(
      begin: 80.0,
      end: 200.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
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

    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null && authProvider.accessToken != null) {
        _currentSubscription =
            await _subscriptionService.getCurrentSubscription(
          authProvider.user!.id,
          authProvider.accessToken!,
        );
        print('Loaded subscription: $_currentSubscription');
        if (mounted) {
          setState(() {});
        }
      } else {
        _currentSubscription = null;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // No active subscription found or error
      print('Error loading subscription data: $e');
      _currentSubscription = null;
      if (mounted) {
        setState(() {});
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9), // Light green background
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side Navigation
          _buildSideNav(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return MouseRegion(
      onEnter: (_) {
        _sidebarAnimationController.forward();
      },
      onExit: (_) {
        _sidebarAnimationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _sidebarWidthAnimation,
        builder: (context, child) {
          return Container(
            width: _sidebarWidthAnimation.value,
            padding: const EdgeInsets.symmetric(vertical: 30),
            color: Colors.white,
            child: Column(
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                ),
                const SizedBox(height: 20),
                _buildNavItem(
                  icon: Icons.access_time_rounded,
                  label: 'Order History',
                  index: 2,
                ),
                const SizedBox(height: 20),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 1,
                ),
                const SizedBox(height: 20),
                _buildNavItem(
                  icon: Icons.mail_outline_rounded,
                  label: 'Messages',
                  index: 3,
                ),
                const SizedBox(height: 20),
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  index: 4,
                ),
                const Spacer(), // Push logout button to bottom
                _buildLogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final iconColor =
        isSelected ? const Color(0xFF33691E) : const Color(0xFF8F9DA9);

    return AnimatedBuilder(
      animation: _sidebarWidthAnimation,
      builder: (context, child) {
        final isExpanded = _sidebarWidthAnimation.value > 100;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFE8F5E8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            color: iconColor,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.name ?? 'User';
        final avatarUrl = user?.avatarUrl;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $userName",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF33691E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateTime.now().toString().split(' ')[0], // Current date
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF8F9DA9),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.notifications_none_outlined,
                    color: Colors.grey),
                const SizedBox(width: 16),
                CircleAvatar(
                  backgroundColor: const Color(0xFF8BC34A),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ],
        );
      },
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
        final List<Reservation> reservations =
            (snapshot.data!['reservations'] as List).cast<Reservation>();

        final upcomingReservations = reservations
            .where((r) => r.reservationTime.isAfter(DateTime.now()))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActionsCard(),
            const SizedBox(height: 30),
            if (_currentSubscription != null) ...[
              _buildSubscriptionStatusCard(),
              const SizedBox(height: 30),
            ],
            _buildRecentReservationsCard(upcomingReservations),
            const SizedBox(height: 30),
            const RecommendationCard(),
          ],
        );
      },
    );
  }

  Widget _buildRecentReservationsCard(List<Reservation> reservations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Reservations',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF33691E),
            ),
          ),
          const SizedBox(height: 20),
          reservations.isEmpty
              ? Center(
                  child: Text(
                    'No upcoming reservations.',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                )
              : Column(
                  children: reservations.take(2).map((reservation) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCEDC8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF8BC34A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Table ${reservation.table.tableNumber} for ${reservation.partySize}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF33691E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(reservation.reservationTime),
                                  style: GoogleFonts.inter(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF33691E),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/menu'),
                      icon: const Icon(Icons.menu_book, color: Colors.white),
                      label: Text(
                        'Order Food',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/dine-in'),
                      icon: const Icon(Icons.table_restaurant,
                          color: Colors.white),
                      label: Text(
                        'Reserve Table',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/subscription-plans'),
                  icon: const Icon(Icons.card_membership, color: Colors.white),
                  label: Text(
                    'Meal Subscription Plans',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF689F38), // Slightly darker green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatusCard() {
    if (_currentSubscription == null || _currentSubscription!.plan == null) {
      return const SizedBox.shrink();
    }

    final plan = _currentSubscription!.plan!;
    final planColor = _getPlanColor(plan);
    final daysRemaining =
        _currentSubscription!.endDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: planColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.card_membership,
                  color: planColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Subscription',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF33691E),
                      ),
                    ),
                    Text(
                      '${plan.name} • ${_currentSubscription!.remainingCredits} credits remaining',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: daysRemaining <= 7
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysRemaining <= 7 ? 'Expires Soon' : 'Active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: daysRemaining <= 7
                        ? Colors.orange[700]
                        : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSubscriptionInfoItem(
                  'Credits Used',
                  '${_currentSubscription!.totalCredits - _currentSubscription!.remainingCredits}/${_currentSubscription!.totalCredits}',
                  Icons.credit_card,
                  planColor,
                ),
              ),
              Expanded(
                child: _buildSubscriptionInfoItem(
                  'Days Remaining',
                  '$daysRemaining days',
                  Icons.schedule,
                  daysRemaining <= 7 ? Colors.orange : planColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentSubscription!.totalCredits -
                    _currentSubscription!.remainingCredits) /
                _currentSubscription!.totalCredits,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(planColor),
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/subscription-dashboard');
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: planColor,
                    side: BorderSide(color: planColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/subscription-plans');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Upgrade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: planColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfoItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    if (plan.name.toLowerCase().contains('basic')) {
      return const Color(0xFF8BC34A);
    } else if (plan.name.toLowerCase().contains('premium')) {
      return const Color(0xFF689F38);
    } else if (plan.name.toLowerCase().contains('elite')) {
      return const Color(0xFF33691E);
    }
    return const Color(0xFF8BC34A);
  }

  Widget _buildLogoutButton() {
    return AnimatedBuilder(
      animation: _sidebarWidthAnimation,
      builder: (context, child) {
        final isExpanded = _sidebarWidthAnimation.value > 100;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 24,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
