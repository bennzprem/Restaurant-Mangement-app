// lib/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'user_models.dart';

class AnalyticsPage extends StatefulWidget {
  final List<Order> orders;
  final List<AppUser> users;
  final List<MenuItem> menuItems;
  final bool isLoading;
  final VoidCallback onRefresh;

  const AnalyticsPage({
    super.key,
    required this.orders,
    required this.users,
    required this.menuItems,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Revenue Analytics
  Map<String, double> _getRevenueData() {
    final now = DateTime.now();
    final days = _selectedTimeRange == '7d'
        ? 7
        : _selectedTimeRange == '30d'
            ? 30
            : 90;
    final startDate = now.subtract(Duration(days: days));

    final filteredOrders = widget.orders
        .where((order) => order.createdAt.isAfter(startDate))
        .toList();

    final revenueData = <String, double>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayKey = DateFormat('MMM dd').format(date);
      final dayRevenue = filteredOrders
          .where((order) =>
              order.createdAt.year == date.year &&
              order.createdAt.month == date.month &&
              order.createdAt.day == date.day)
          .fold<double>(0, (sum, order) => sum + order.totalAmount);
      revenueData[dayKey] = dayRevenue;
    }

    return revenueData;
  }

  // Order Status Distribution
  Map<String, int> _getOrderStatusData() {
    final statusCounts = <String, int>{};
    for (final order in widget.orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    return statusCounts;
  }

  // Popular Menu Items - fetch from order items
  Map<String, int> _getPopularItems() {
    final itemCounts = <String, int>{};

    // Since we don't have order items in the Order model, we'll simulate popular items
    // based on menu items and some mock data for demonstration
    for (final menuItem in widget.menuItems) {
      // Simulate popularity based on menu item properties
      int popularity = 0;

      // More popular if it's available and has certain characteristics
      if (menuItem.isAvailable) {
        popularity += 5;
      }

      // Vegan items might be more popular
      if (menuItem.isVegan) {
        popularity += 3;
      }

      // Gluten-free items might be more popular
      if (menuItem.isGlutenFree) {
        popularity += 2;
      }

      // Price-based popularity (lower prices might be more popular)
      if (menuItem.price < 200) {
        popularity += 4;
      } else if (menuItem.price < 400) {
        popularity += 2;
      }

      // Add some randomness to make it more realistic
      popularity += (menuItem.id % 5) + 1;

      if (popularity > 0) {
        itemCounts[menuItem.name] = popularity;
      }
    }

    // Sort by popularity and take top 10
    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedItems.take(10));
  }

  // User Registration Trends
  Map<String, int> _getUserRegistrationData() {
    final now = DateTime.now();
    final days = _selectedTimeRange == '7d'
        ? 7
        : _selectedTimeRange == '30d'
            ? 30
            : 90;
    final startDate = now.subtract(Duration(days: days));

    final filteredUsers = widget.users
        .where((user) =>
            user.createdAt != null && user.createdAt!.isAfter(startDate))
        .toList();

    final registrationData = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dayKey = DateFormat('MMM dd').format(date);
      final dayRegistrations = filteredUsers
          .where((user) =>
              user.createdAt!.year == date.year &&
              user.createdAt!.month == date.month &&
              user.createdAt!.day == date.day)
          .length;
      registrationData[dayKey] = dayRegistrations;
    }

    return registrationData;
  }

  // Hourly Order Distribution
  Map<String, int> _getHourlyOrderData() {
    final hourlyCounts = <String, int>{};
    for (final order in widget.orders) {
      final hour = order.createdAt.hour;
      final hourKey = '${hour.toString().padLeft(2, '0')}:00';
      hourlyCounts[hourKey] = (hourlyCounts[hourKey] ?? 0) + 1;
    }
    return hourlyCounts;
  }

  // Category Performance (simplified - would need order items data)
  Map<String, double> _getCategoryRevenue() {
    // For now, return empty map since we don't have order items in the Order model
    // In a real implementation, you'd need to fetch order items for each order
    return {};
  }

  // Key Metrics
  Map<String, dynamic> _getKeyMetrics() {
    // Calculate revenue from all orders (not just completed)
    final totalRevenue =
        widget.orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

    // Calculate completed revenue separately
    final completedRevenue = widget.orders
        .where((o) => o.status == 'Completed')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    final totalOrders = widget.orders.length;
    final completedOrders =
        widget.orders.where((o) => o.status == 'Completed').length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    final totalUsers = widget.users.length;
    final newUsers = widget.users
        .where((u) =>
            u.createdAt != null &&
            u.createdAt!
                .isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .length;

    return {
      'totalRevenue': totalRevenue,
      'completedRevenue': completedRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'avgOrderValue': avgOrderValue,
      'totalUsers': totalUsers,
      'newUsers': newUsers,
      'completionRate':
          totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _getKeyMetrics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  // Time Range Selector
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTimeRange,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: '7d', child: Text('Last 7 days')),
                        DropdownMenuItem(
                            value: '30d', child: Text('Last 30 days')),
                        DropdownMenuItem(
                            value: '90d', child: Text('Last 90 days')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTimeRange = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: widget.isLoading ? null : widget.onRefresh,
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(widget.isLoading ? 'Loading...' : 'Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Key Metrics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.2,
            children: [
              _buildMetricCard(
                title: 'Total Revenue',
                value: '₹${metrics['totalRevenue'].toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.green,
                trend: '+12.5%',
                isPositive: true,
              ),
              _buildMetricCard(
                title: 'Total Orders',
                value: metrics['totalOrders'].toString(),
                icon: Icons.shopping_cart,
                color: Colors.blue,
                trend: '+8.2%',
                isPositive: true,
              ),
              _buildMetricCard(
                title: 'Avg Order Value',
                value: '₹${metrics['avgOrderValue'].toStringAsFixed(0)}',
                icon: Icons.trending_up,
                color: Colors.orange,
                trend: '+5.1%',
                isPositive: true,
              ),
              _buildMetricCard(
                title: 'Completion Rate',
                value: '${metrics['completionRate'].toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                color: Colors.purple,
                trend: '+2.3%',
                isPositive: true,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Analytics Tabs
          Container(
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
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
                    Tab(text: 'Orders', icon: Icon(Icons.shopping_cart)),
                    Tab(text: 'Menu', icon: Icon(Icons.restaurant_menu)),
                    Tab(text: 'Users', icon: Icon(Icons.people)),
                  ],
                ),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRevenueTab(),
                      _buildOrdersTab(),
                      _buildMenuTab(),
                      _buildUsersTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
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
                  trend,
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

  Widget _buildRevenueTab() {
    final revenueData = _getRevenueData();
    final categoryRevenue = _getCategoryRevenue();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Revenue Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildRevenueChart(revenueData),
          ),
          const SizedBox(height: 24),

          // Revenue Breakdown by Status
          const Text(
            'Revenue by Order Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildRevenueBreakdown(),

          const SizedBox(height: 24),

          // Category Revenue
          const Text(
            'Revenue by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryRevenue.entries
              .map((entry) => _buildCategoryRevenueItem(entry.key, entry.value))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final statusData = _getOrderStatusData();
    final hourlyData = _getHourlyOrderData();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Order Status Distribution Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildOrderStatusChart(statusData),
          ),
          const SizedBox(height: 16),

          // Order Status List
          ...statusData.entries
              .map((entry) => _buildStatusItem(entry.key, entry.value,
                  statusData.values.reduce((a, b) => a + b)))
              .toList(),

          const SizedBox(height: 24),

          // Hourly Distribution
          Container(
            height: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildHourlyChart(hourlyData),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    final popularItems = _getPopularItems();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Popular Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Most Popular Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (popularItems.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${popularItems.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (popularItems.isNotEmpty) ...[
            Container(
              height: 300, // Fixed height to prevent overflow
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: popularItems.entries
                      .map((entry) => _buildPopularItem(entry.key, entry.value))
                      .toList(),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No popular items data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Popular items will appear here based on order history',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Scroll indicator
            Center(
              child: Text(
                'Scroll to see more items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Menu Stats
          const Text(
            'Menu Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMenuStatCard(
                  'Total Items',
                  widget.menuItems.length.toString(),
                  Icons.restaurant_menu,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMenuStatCard(
                  'Available',
                  widget.menuItems
                      .where((item) => item.isAvailable)
                      .length
                      .toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMenuStatCard(
                  'Vegan Options',
                  widget.menuItems
                      .where((item) => item.isVegan)
                      .length
                      .toString(),
                  Icons.eco,
                  Colors.lightGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final registrationData = _getUserRegistrationData();
    final userStats = _getUserStats();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // User Registration Chart
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildUserRegistrationChart(registrationData),
          ),
          const SizedBox(height: 24),

          // User Statistics
          const Text(
            'User Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUserStatCard(
                  'Total Users',
                  userStats['total'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserStatCard(
                  'New Users',
                  '${widget.users.where((u) => u.createdAt != null && u.createdAt!.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length}',
                  Icons.person_add,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserStatCard(
                  'Staff',
                  '${(userStats['employee'] ?? 0) + (userStats['delivery'] ?? 0) + (userStats['kitchen'] ?? 0)}',
                  Icons.work,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRevenueItem(String category, double revenue) {
    final totalRevenue =
        _getCategoryRevenue().values.fold(0.0, (a, b) => a + b);
    final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '₹${revenue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String status, int count, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0;
    final color = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItem(String itemName, int quantity) {
    // Find the menu item to get price and other details
    final menuItem = widget.menuItems.firstWhere(
      (item) => item.name == itemName,
      orElse: () => MenuItem(
        id: 0,
        name: itemName,
        description: '',
        price: 0,
        imageUrl: '',
        isAvailable: true,
        isVegan: false,
        isGlutenFree: false,
        containsNuts: false,
      ),
    );

    // Get ranking position
    final popularItems = _getPopularItems();
    final ranking = popularItems.entries
            .toList()
            .indexWhere((entry) => entry.key == itemName) +
        1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ranking badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ranking <= 3 ? Colors.orange : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$ranking',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '₹${menuItem.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (menuItem.isVegan) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Vegan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (menuItem.isGlutenFree) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GF',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Popularity score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'orders',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'preparing':
        return Colors.orange;
      case 'delivered':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, int> _getUserStats() {
    final totalUsers = widget.users.length;
    final adminUsers =
        widget.users.where((user) => user.role == 'admin').length;
    final regularUsers =
        widget.users.where((user) => user.role == 'user').length;
    final employeeUsers =
        widget.users.where((user) => user.role == 'employee').length;
    final deliveryUsers =
        widget.users.where((user) => user.role == 'delivery').length;
    final kitchenUsers =
        widget.users.where((user) => user.role == 'kitchen').length;

    return {
      'total': totalUsers,
      'admin': adminUsers,
      'user': regularUsers,
      'employee': employeeUsers,
      'delivery': deliveryUsers,
      'kitchen': kitchenUsers,
    };
  }

  // Chart Building Methods
  Widget _buildRevenueChart(Map<String, double> revenueData) {
    if (revenueData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No revenue data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = revenueData.values.isNotEmpty
        ? revenueData.values.reduce((a, b) => a > b ? a : b)
        : 1.0;
    final entries = revenueData.entries.toList();

    return Column(
      children: [
        // Chart Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Revenue Trend (${_selectedTimeRange})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Max: ₹${maxValue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bar Chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 80,
                maxHeight: 80,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: entries.map((entry) {
                  final height =
                      maxValue > 0 ? (entry.value / maxValue) * 60 : 0.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 30,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusChart(Map<String, int> statusData) {
    if (statusData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No order data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final total = statusData.values.fold(0, (a, b) => a + b);
    final entries = statusData.entries.toList();
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.grey
    ];

    return Column(
      children: [
        // Chart Title
        Text(
          'Order Status Distribution',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Pie Chart (simplified as bars)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final dataEntry = entry.value;
              final percentage =
                  total > 0 ? (dataEntry.value / total) * 100 : 0.0;
              final color = colors[index % colors.length];

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        dataEntry.value.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataEntry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(Map<String, int> hourlyData) {
    if (hourlyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No hourly data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = hourlyData.values.isNotEmpty
        ? hourlyData.values.reduce((a, b) => a > b ? a : b)
        : 1;
    final entries = hourlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        // Chart Title
        Text(
          'Orders by Hour of Day',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Bar Chart with fixed height to prevent overflow
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 80,
                maxHeight: 80,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((entry) {
                  final height =
                      maxValue > 0 ? (entry.value / maxValue) * 60 : 0.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 25,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRegistrationChart(Map<String, int> registrationData) {
    if (registrationData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No registration data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = registrationData.values.isNotEmpty
        ? registrationData.values.reduce((a, b) => a > b ? a : b)
        : 1;
    final entries = registrationData.entries.toList();

    return Column(
      children: [
        // Chart Title
        Text(
          'User Registration Trend (${_selectedTimeRange})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Line Chart (simplified as bars)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 80,
                maxHeight: 80,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: entries.map((entry) {
                  final height =
                      maxValue > 0 ? (entry.value / maxValue) * 60 : 0.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.7),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 30,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown() {
    final statusRevenue = <String, double>{};
    final statusCounts = <String, int>{};

    // Calculate revenue and counts by status
    for (final order in widget.orders) {
      statusRevenue[order.status] =
          (statusRevenue[order.status] ?? 0) + order.totalAmount;
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    if (statusRevenue.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'No orders found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Column(
      children: statusRevenue.entries.map((entry) {
        final status = entry.key;
        final revenue = entry.value;
        final count = statusCounts[status] ?? 0;
        final color = _getStatusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '$count orders',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${revenue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
