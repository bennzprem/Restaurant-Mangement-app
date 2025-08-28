// lib/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'theme.dart';
import 'manage_users_page.dart';
import 'manage_menu_page.dart';
import 'api_service.dart';
import 'user_models.dart';
import 'models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<AppUser> _users = [];
  List<Order> _orders = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeToOrderChanges();
  }

  void _subscribeToOrderChanges() {
    final supabase = Supabase.instance.client;
    supabase
        .channel('orders-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _loadDashboardData();
          },
        )
        .subscribe();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _apiService.getAllUsers();
      final orders = await _apiService.getAllOrders();
      final menuItems = await _apiService.getAllMenuItems();
      setState(() {
        _users = users;
        _orders = orders;
        _menuItems = menuItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error silently for now
    }
  }

  Map<String, int> _getUserStats() {
    final totalUsers = _users.length;
    final adminUsers = _users.where((user) => user.role == 'admin').length;
    final regularUsers = _users.where((user) => user.role == 'user').length;
    final employeeUsers =
        _users.where((user) => user.role == 'employee').length;
    final deliveryUsers =
        _users.where((user) => user.role == 'delivery').length;
    final kitchenUsers = _users.where((user) => user.role == 'kitchen').length;

    return {
      'total': totalUsers,
      'admin': adminUsers,
      'user': regularUsers,
      'employee': employeeUsers,
      'delivery': deliveryUsers,
      'kitchen': kitchenUsers,
    };
  }

  Map<String, dynamic> _getOrderStats() {
    final totalOrders = _orders.length;
    final completedOrders =
        _orders.where((order) => order.status == 'Completed').length;
    final pendingOrders =
        _orders.where((order) => order.status == 'Preparing').length;
    final deliveredOrders =
        _orders.where((order) => order.status == 'Delivered').length;
    final cancelledOrders =
        _orders.where((order) => order.status == 'Cancelled').length;

    final totalRevenue =
        _orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
    final completedRevenue = _orders
        .where((order) => order.status == 'Completed')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return {
      'total': totalOrders,
      'completed': completedOrders,
      'pending': pendingOrders,
      'delivered': deliveredOrders,
      'cancelled': cancelledOrders,
      'totalRevenue': totalRevenue,
      'completedRevenue': completedRevenue,
    };
  }

  Map<String, dynamic> _getMenuStats() {
    final totalItems = _menuItems.length;
    final availableItems = _menuItems.where((item) => item.isAvailable).length;
    final unavailableItems =
        _menuItems.where((item) => !item.isAvailable).length;
    final veganItems = _menuItems.where((item) => item.isVegan).length;
    final glutenFreeItems =
        _menuItems.where((item) => item.isGlutenFree).length;
    final nutFreeItems = _menuItems.where((item) => !item.containsNuts).length;

    final totalValue =
        _menuItems.fold<double>(0, (sum, item) => sum + item.price);
    final averagePrice = totalItems > 0 ? totalValue / totalItems : 0;

    return {
      'total': totalItems,
      'available': availableItems,
      'unavailable': unavailableItems,
      'vegan': veganItems,
      'glutenFree': glutenFreeItems,
      'nutFree': nutFreeItems,
      'totalValue': totalValue,
      'averagePrice': averagePrice,
    };
  }

  Widget build(BuildContext context) {
    // Check if user is logged in and is admin, if not redirect to home
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to access admin dashboard.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin privileges required.'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Admin Profile Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.watch<AuthProvider>().user?.name ??
                                  'Admin',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.people,
                        title: 'User Management',
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Icons.restaurant_menu,
                        title: 'Menu Management',
                        index: 2,
                      ),
                      _buildNavItem(
                        icon: Icons.shopping_cart,
                        title: 'Orders',
                        index: 3,
                      ),
                      _buildNavItem(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        index: 4,
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        title: 'Settings',
                        index: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return _buildUserManagement();
      case 2:
        return _buildMenuManagement();
      case 3:
        return _buildOrders();
      case 4:
        return _buildAnalytics();
      case 5:
        return _buildSettings();
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadDashboardData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isLoading ? 'Loading...' : 'Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: 'Total Users',
                value: _isLoading ? '...' : _users.length.toString(),
                icon: Icons.people,
                color: Colors.blue,
                change: _isLoading ? '' : '${_users.length} users',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Total Orders',
                value:
                    _isLoading ? '...' : _getOrderStats()['total'].toString(),
                icon: Icons.shopping_cart,
                color: Colors.green,
                change: _isLoading ? '' : '${_getOrderStats()['total']} orders',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Revenue',
                value: _isLoading
                    ? '...'
                    : '₹${_getOrderStats()['totalRevenue'].toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.orange,
                change: _isLoading
                    ? ''
                    : '₹${_getOrderStats()['totalRevenue'].toStringAsFixed(0)} total',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Menu Items',
                value: _isLoading ? '...' : _getMenuStats()['total'].toString(),
                icon: Icons.restaurant_menu,
                color: Colors.purple,
                change: _isLoading ? '' : '${_getMenuStats()['total']} items',
                isPositive: true,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Recent Activity
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                if (_users.isNotEmpty ||
                    _orders.isNotEmpty ||
                    _menuItems.isNotEmpty) ...[
                  if (_users.isNotEmpty) ...[
                    _buildActivityItem(
                      icon: Icons.people,
                      title: 'Total users in system',
                      subtitle: '${_users.length} registered users',
                      time: 'Current',
                      color: Colors.blue,
                    ),
                    if (_users.length > 1) ...[
                      _buildActivityItem(
                        icon: Icons.person,
                        title: 'Latest user',
                        subtitle: '${_users.last.name} joined the platform',
                        time: 'Recently',
                        color: Colors.green,
                      ),
                    ],
                    _buildActivityItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin users',
                      subtitle:
                          '${_getUserStats()['admin'] ?? 0} admin accounts',
                      time: 'Current',
                      color: Colors.red,
                    ),
                    _buildActivityItem(
                      icon: Icons.person_outline,
                      title: 'Regular users',
                      subtitle:
                          '${_getUserStats()['user'] ?? 0} customer accounts',
                      time: 'Current',
                      color: Colors.green,
                    ),
                    _buildActivityItem(
                      icon: Icons.work,
                      title: 'Staff members',
                      subtitle:
                          '${(_getUserStats()['employee'] ?? 0) + (_getUserStats()['delivery'] ?? 0) + (_getUserStats()['kitchen'] ?? 0)} total staff',
                      time: 'Current',
                      color: Colors.orange,
                    ),
                  ],
                  if (_orders.isNotEmpty) ...[
                    _buildActivityItem(
                      icon: Icons.shopping_cart,
                      title: 'Total orders',
                      subtitle: '${_getOrderStats()['total']} orders placed',
                      time: 'Current',
                      color: Colors.green,
                    ),
                    if (_orders.isNotEmpty) ...[
                      _buildActivityItem(
                        icon: Icons.check_circle,
                        title: 'Latest order',
                        subtitle:
                            'Order #${_orders.first.id} - ₹${_orders.first.totalAmount.toStringAsFixed(2)}',
                        time: 'Recently',
                        color: Colors.blue,
                      ),
                    ],
                    _buildActivityItem(
                      icon: Icons.pending,
                      title: 'Pending orders',
                      subtitle:
                          '${_getOrderStats()['pending']} orders preparing',
                      time: 'Current',
                      color: Colors.orange,
                    ),
                    _buildActivityItem(
                      icon: Icons.done_all,
                      title: 'Completed orders',
                      subtitle:
                          '${_getOrderStats()['completed']} orders completed',
                      time: 'Current',
                      color: Colors.green,
                    ),
                  ],
                  if (_menuItems.isNotEmpty) ...[
                    _buildActivityItem(
                      icon: Icons.restaurant_menu,
                      title: 'Total menu items',
                      subtitle: '${_getMenuStats()['total']} items in menu',
                      time: 'Current',
                      color: Colors.purple,
                    ),
                    _buildActivityItem(
                      icon: Icons.check_circle_outline,
                      title: 'Available items',
                      subtitle:
                          '${_getMenuStats()['available']} items available',
                      time: 'Current',
                      color: Colors.green,
                    ),
                    _buildActivityItem(
                      icon: Icons.eco,
                      title: 'Vegan options',
                      subtitle: '${_getMenuStats()['vegan']} vegan items',
                      time: 'Current',
                      color: Colors.lightGreen,
                    ),
                    _buildActivityItem(
                      icon: Icons.restaurant,
                      title: 'Dietary options',
                      subtitle:
                          '${_getMenuStats()['glutenFree']} gluten-free, ${_getMenuStats()['nutFree']} nut-free',
                      time: 'Current',
                      color: Colors.orange,
                    ),
                  ],
                ] else ...[
                  _buildActivityItem(
                    icon: Icons.people_outline,
                    title: 'No data yet',
                    subtitle: 'No users or orders have been created yet',
                    time: 'Current',
                    color: Colors.grey,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagement() {
    return ManageUsersPage(
      onUserUpdated: _loadDashboardData,
    );
  }

  Widget _buildMenuManagement() {
    return ManageMenuPage(
      onMenuUpdated: _loadDashboardData,
    );
  }

  Widget _buildOrders() {
    return const Center(
      child: Text(
        'Orders - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }

  Widget _buildAnalytics() {
    return const Center(
      child: Text(
        'Analytics - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }

  Widget _buildSettings() {
    return const Center(
      child: Text(
        'Settings - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }
}
