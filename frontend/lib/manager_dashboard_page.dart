// lib/manager_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'auth_provider.dart';
import 'theme.dart';
import 'api_service.dart';
import 'user_models.dart';
import 'models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/staff_management_section.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<AppUser> _staff = [];
  List<Order> _orders = [];
  int _ordersCount = 0;
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _tables = [];
  RealtimeChannel? _ordersChannel;
  Timer? _pollTimer;
  RealtimeChannel? _tablesChannel;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeToOrderChanges();
    _loadTables();
    _subscribeToTableChanges();
  }

  void _subscribeToOrderChanges() {
    final supabase = Supabase.instance.client;
    _ordersChannel = supabase
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

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _pollTimer?.cancel();
    _tablesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _showAddTableDialog() async {
    final numberController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    final locationController = TextEditingController();
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Add New Table'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Table Number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Preference (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Table Code (optional, e.g. TBL012)',
                  helperText:
                      'If provided, an active session will be created with this code',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final number = int.tryParse(numberController.text.trim());
              final capacity = int.tryParse(capacityController.text.trim());
              if (number == null || number <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid table number')),
                );
                return;
              }
              if (capacity == null || capacity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid capacity')),
                );
                return;
              }
              try {
                await _apiService.createTable(
                  tableNumber: number,
                  capacity: capacity,
                  locationPreference: locationController.text.trim().isEmpty
                      ? null
                      : locationController.text.trim(),
                  sessionCode: codeController.text.trim().isEmpty
                      ? null
                      : codeController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create table: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Refresh counts/overview and tables list immediately
      _loadDashboardData();
      try {
        final data = await _apiService.getTables();
        if (mounted) setState(() => _tables = data);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table created successfully')),
        );
      }
    }
  }

  Future<void> _loadTables() async {
    try {
      final data = await _apiService.getTables();
      if (mounted) setState(() => _tables = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tables: $e')),
        );
      }
    }
  }

  void _subscribeToTableChanges() {
    final supabase = Supabase.instance.client;
    _tablesChannel = supabase
        .channel('tables-and-sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tables',
          callback: (_) => _loadTables(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'table_sessions',
          callback: (_) => _loadTables(),
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
      final ordersCount = await _apiService.getOrdersCountAccurate();
      final menuItems = await _apiService.getAllMenuItems();

      // Filter staff (exclude customers)
      final staff = users
          .where((user) =>
              user.role == 'employee' ||
              user.role == 'delivery' ||
              user.role == 'kitchen' ||
              user.role == 'admin' ||
              user.role == 'manager')
          .toList();

      setState(() {
        _staff = staff;
        _orders = orders;
        _ordersCount = ordersCount;
        _menuItems = menuItems;
        // Load tables lazily when Tables tab opens
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading dashboard data: $e');
    }
  }

  Map<String, int> _getStaffStats() {
    final totalStaff = _staff.length;
    final managers = _staff.where((user) => user.role == 'manager').length;
    final employees = _staff.where((user) => user.role == 'employee').length;
    final deliveryStaff =
        _staff.where((user) => user.role == 'delivery').length;
    final kitchenStaff = _staff.where((user) => user.role == 'kitchen').length;
    final admins = _staff.where((user) => user.role == 'admin').length;

    return {
      'total': totalStaff,
      'managers': managers,
      'employees': employees,
      'delivery': deliveryStaff,
      'kitchen': kitchenStaff,
      'admins': admins,
    };
  }

  Map<String, dynamic> _getOrderStats() {
    final totalOrders = _ordersCount > 0 ? _ordersCount : _orders.length;
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

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in and is manager, if not redirect to home
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to access manager dashboard.'),
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

    if (!authProvider.isManager && !authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Manager privileges required.'),
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
      backgroundColor: Colors.grey[100]!,
      appBar: AppBar(
        title: const Text(
          'Manager Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate to home instead of just popping
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                try {
                  await context.read<AuthProvider>().signOut();
                  // Clear all routes and navigate to home
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                } catch (e) {
                  print('Error during logout: $e');
                  // Force navigation even if logout fails
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Sidebar Navigation
              Container(
                width: constraints.maxWidth < 800 ? 200 : 250,
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
                    // Manager Profile Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.manage_accounts,
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
                                      'Manager',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Manager',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600]!,
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
                            title: 'Overview',
                            index: 0,
                          ),
                          _buildNavItem(
                            icon: Icons.people,
                            title: 'Staff Management',
                            index: 1,
                          ),
                          _buildNavItem(
                            icon: Icons.shopping_cart,
                            title: 'Orders',
                            index: 2,
                          ),
                          _buildNavItem(
                            icon: Icons.restaurant_menu,
                            title: 'Menu',
                            index: 3,
                          ),
                          _buildNavItem(
                            icon: Icons.analytics,
                            title: 'Analytics',
                            index: 4,
                          ),
                          _buildNavItem(
                            icon: Icons.schedule,
                            title: 'Schedule',
                            index: 5,
                          ),
                          _buildNavItem(
                            icon: Icons.table_bar,
                            title: 'Tables',
                            index: 6,
                          ),
                          _buildNavItem(
                            icon: Icons.settings,
                            title: 'Settings',
                            index: 7,
                          ),
                          const Divider(color: Colors.grey, height: 32),
                          _buildLogoutItem(),
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
          );
        },
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
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600]!,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[600]!,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Show confirmation dialog
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              try {
                await context.read<AuthProvider>().signOut();
                // Clear all routes and navigate to home
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              } catch (e) {
                print('Error during logout: $e');
                // Force navigation even if logout fails
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
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
        return _buildOverview();
      case 1:
        return _buildStaffManagement();
      case 2:
        return _buildOrders();
      case 3:
        return _buildMenu();
      case 4:
        return _buildAnalytics();
      case 5:
        return _buildSchedule();
      case 6:
        return _buildTables();
      case 7:
        return _buildSettings();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manager Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(children: [
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
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAddTableDialog,
                  icon: const Icon(Icons.table_restaurant),
                  label: const Text('Add Table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 4;
              if (constraints.maxWidth < 1200) crossAxisCount = 3;
              if (constraints.maxWidth < 900) crossAxisCount = 2;
              if (constraints.maxWidth < 600) crossAxisCount = 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    title: 'Total Staff',
                    value: _isLoading
                        ? '...'
                        : _getStaffStats()['total'].toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                    change: _isLoading
                        ? ''
                        : '${_getStaffStats()['total']} employees',
                    isPositive: true,
                  ),
                  _buildStatCard(
                    title: 'Active Orders',
                    value: _isLoading
                        ? '...'
                        : _getOrderStats()['pending'].toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                    change: _isLoading
                        ? ''
                        : '${_getOrderStats()['pending']} pending',
                    isPositive: true,
                  ),
                  _buildStatCard(
                    title: 'Today\'s Revenue',
                    value: _isLoading
                        ? '...'
                        : '₹${_getOrderStats()['totalRevenue'].toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    change: _isLoading
                        ? ''
                        : '₹${_getOrderStats()['totalRevenue'].toStringAsFixed(0)} total',
                    isPositive: true,
                  ),
                  _buildStatCard(
                    title: 'Menu Items',
                    value: _isLoading ? '...' : _menuItems.length.toString(),
                    icon: Icons.restaurant_menu,
                    color: Colors.purple,
                    change: _isLoading ? '' : '${_menuItems.length} items',
                    isPositive: true,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Staff Overview
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Staff Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: const Text('View All Staff'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_staff.isNotEmpty) ...[
                  ...List.generate(
                    _staff.take(5).length,
                    (index) => _buildStaffItem(_staff[index]),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No staff members found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
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
                    color: isPositive
                        ? Colors.green
                        : Colors.red,
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffItem(AppUser staff) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRoleColor(staff.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _getRoleColor(staff.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  staff.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(staff.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              staff.role.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getRoleColor(staff.role),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.indigo;
      case 'employee':
        return Colors.blue;
      case 'delivery':
        return Colors.orange;
      case 'kitchen':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Widget _buildStaffManagement() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: StaffManagementSection(
        staff: _staff,
        onStaffUpdated: _loadDashboardData,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildOrders() {
    return const Center(
      child: Text(
        'Orders Management - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }

  Widget _buildMenu() {
    return const Center(
      child: Text(
        'Menu Management - Coming Soon',
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

  Widget _buildSchedule() {
    return const Center(
      child: Text(
        'Schedule Management - Coming Soon',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }

  Widget _buildTables() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tables',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTableDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Table'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Use Add Table to register a table and optional code for QR.',
                style: TextStyle(color: Colors.grey[600]!),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadTables,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_tables.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
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
                children: const [
                  Icon(Icons.table_bar, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No tables loaded. Tap Refresh to fetch tables.'),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tables.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (context, i) {
                final t = _tables[i];
                final occupied = t['occupied'] == true;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: occupied ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_bar,
                        color: occupied ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Table #${t['table_number']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Text('Capacity: ${t['capacity'] ?? '-'}'),
                            if (t['location_preference'] != null)
                              Text('Location: ${t['location_preference']}'),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: occupied
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              occupied ? 'Occupied' : 'Available',
                              style: TextStyle(
                                color: occupied ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (t['active_session_code'] != null) ...[
                            const SizedBox(height: 6),
                            Text('Code: ${t['active_session_code']}'),
                          ],
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await _apiService.toggleTable(t['id']);
                                await _loadTables();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Toggle failed: $e')),
                                );
                              }
                            },
                            icon: Icon(
                              occupied ? Icons.lock_open : Icons.lock,
                              size: 16,
                            ),
                            label: Text(
                                occupied ? 'Set Available' : 'Set Occupied'),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
        ],
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
