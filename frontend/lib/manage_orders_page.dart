// lib/manage_orders_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'models.dart';
import 'user_models.dart';
import 'theme.dart';

class ManageOrdersPage extends StatefulWidget {
  final VoidCallback? onOrderUpdated;

  const ManageOrdersPage({super.key, this.onOrderUpdated});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  List<AppUser> _users = [];
  List<MenuItem> _menuItems = [];
  Map<int, List<Map<String, dynamic>>> _orderItems = {};
  Map<int, AppUser> _orderUsers = {};

  bool _isLoading = false;
  String _selectedStatus = 'All';
  String _selectedSortBy = 'Newest First';

  final List<String> _statusOptions = [
    'All',
    'Preparing',
    'Ready',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Highest Amount',
    'Lowest Amount',
    'Status A-Z',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _apiService.getAllOrders();
      final users = await _apiService.getAllUsers();
      final menuItems = await _apiService.getAllMenuItems();

      // Load order items for each order
      final orderItems = await _loadOrderItems(orders);

      setState(() {
        _allOrders = orders;
        _users = users;
        _menuItems = menuItems;
        _orderItems = orderItems;
        _orderUsers = _mapOrderUsers(orders, users);
        _isLoading = false;
      });

      _filterOrders();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> _loadOrderItems(
      List<Order> orders) async {
    final Map<int, List<Map<String, dynamic>>> orderItems = {};

    for (final order in orders) {
      try {
        final items = await _apiService.getOrderItems(order.id);
        orderItems[order.id] = items;
      } catch (e) {
        print('Error loading items for order ${order.id}: $e');
        orderItems[order.id] = [];
      }
    }

    return orderItems;
  }

  Map<int, AppUser> _mapOrderUsers(List<Order> orders, List<AppUser> users) {
    final Map<int, AppUser> orderUsers = {};

    for (final order in orders) {
      if (order.userId != null) {
        final user = users.firstWhere(
          (u) => u.id == order.userId,
          orElse: () => AppUser(
            id: 'unknown',
            name: 'Unknown User',
            role: 'user',
          ),
        );
        orderUsers[order.id] = user;
      } else {
        orderUsers[order.id] = AppUser(
          id: 'unknown',
          name: 'Unknown User',
          role: 'user',
        );
      }
    }

    return orderUsers;
  }

  void _filterOrders() {
    List<Order> filtered = List.from(_allOrders);

    // Filter by search text
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final user = _orderUsers[order.id];
        return user?.name.toLowerCase().contains(searchLower) == true ||
            order.id.toString().contains(searchLower) ||
            order.deliveryAddress.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Filter by status
    if (_selectedStatus != 'All') {
      filtered =
          filtered.where((order) => order.status == _selectedStatus).toList();
    }

    // Sort orders
    filtered = _sortOrders(filtered);

    setState(() {
      _filteredOrders = filtered;
    });
  }

  List<Order> _sortOrders(List<Order> orders) {
    switch (_selectedSortBy) {
      case 'Newest First':
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest First':
        orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Highest Amount':
        orders.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'Lowest Amount':
        orders.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'Status A-Z':
        orders.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
    return orders;
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _apiService.updateOrderStatus(order.id, newStatus);

      // Update local state
      setState(() {
        final index = _allOrders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _allOrders[index] = Order(
            id: order.id,
            totalAmount: order.totalAmount,
            status: newStatus,
            createdAt: order.createdAt,
            deliveryAddress: order.deliveryAddress,
            userId: order.userId,
          );
        }
      });

      _filterOrders();
      widget.onOrderUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(Order order) {
    final orderItems = _orderItems[order.id] ?? [];
    final user = _orderUsers[order.id];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderDetailRow('Customer', user?.name ?? 'Unknown'),
              _buildOrderDetailRow('Status', order.status),
              _buildOrderDetailRow(
                  'Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
              _buildOrderDetailRow('Order Date',
                  DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)),
              _buildOrderDetailRow('Delivery Address', order.deliveryAddress),
              const SizedBox(height: 16),
              const Text(
                'Order Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...orderItems.map((item) => _buildOrderItemRow(item)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(Map<String, dynamic> item) {
    final menuItem = _menuItems.firstWhere(
      (mi) => mi.id == item['menu_item_id'],
      orElse: () => MenuItem(
        id: 0,
        name: 'Unknown Item',
        description: '',
        price: 0.0,
        imageUrl: '',
        isAvailable: false,
        isVegan: false,
        isGlutenFree: false,
        containsNuts: false,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menuItem.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Qty: ${item['quantity']} × ₹${item['price_at_order']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item['quantity'] * (item['price_at_order'] as num)).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return Colors.blue;
      case 'Out for Delivery':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Orders Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadData,
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
              ],
            ),
          ),

          // Statistics Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Orders',
                    _allOrders.length.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Preparing',
                    _allOrders
                        .where((o) => o.status == 'Preparing')
                        .length
                        .toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Ready',
                    _allOrders
                        .where((o) => o.status == 'Ready')
                        .length
                        .toString(),
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Delivered',
                    _allOrders
                        .where((o) => o.status == 'Delivered')
                        .length
                        .toString(),
                    Icons.done_all,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Filters and Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search by customer name, order ID, or address...',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    underline: const SizedBox(),
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                      _filterOrders();
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Sort Filter
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSortBy,
                    underline: const SizedBox(),
                    items: _sortOptions.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(sort),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSortBy = value!;
                      });
                      _filterOrders();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final user = _orderUsers[order.id];
                          final orderItems = _orderItems[order.id] ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                // Order Header
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // Order Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Order #${order.id}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            order.status)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: _getStatusColor(
                                                          order.status),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    order.status,
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                          order.status),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Customer: ${user?.name ?? 'Unknown'}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Amount and Actions
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${order.totalAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _showOrderDetails(order),
                                                icon: const Icon(
                                                    Icons.visibility),
                                                label: const Text('View'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context).primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              PopupMenuButton<String>(
                                                onSelected: (status) =>
                                                    _updateOrderStatus(
                                                        order, status),
                                                itemBuilder: (context) =>
                                                    _statusOptions
                                                        .where((status) =>
                                                            status != 'All')
                                                        .map((status) =>
                                                            PopupMenuItem(
                                                              value: status,
                                                              child: Text(
                                                                  'Mark as $status'),
                                                            ))
                                                        .toList(),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(context).primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Update Status',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Order Items Preview
                                if (orderItems.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.restaurant_menu,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${orderItems.length} item${orderItems.length == 1 ? '' : 's'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
