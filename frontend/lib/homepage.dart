import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';

import 'auth_provider.dart'; // keep your auth provider import
import 'menu_screen_with_location.dart';
import 'dine_in_page.dart';
import 'api_service.dart';
import 'models.dart';

import 'widgets/header_widget.dart';
import 'widgets/animated_background.dart';
import 'widgets/about_section.dart';
import 'widgets/ai_culinary_curator_section.dart';
import 'widgets/culinary_philosophy_section.dart';
import 'widgets/footer_widget.dart';
import 'widgets/order_tracking_button.dart';
import 'services/order_tracking_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OrderTrackingService _orderTrackingService = OrderTrackingService();
  bool _isTrackingInitialized = false;

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage initState');
    // Check if service already has orders (for hot restart)
    if (_orderTrackingService.hasActiveOrders) {
      print('🔍 Service already has orders, initializing immediately');
      setState(() {
        _isTrackingInitialized = true;
      });
    }
    // Listen to service changes
    _orderTrackingService.addListener(_onServiceChanged);
    _initializeOrderTracking();
  }

  void _onServiceChanged() {
    print(
        '🔄 Service changed: hasOrders=${_orderTrackingService.hasActiveOrders}');
    if (_orderTrackingService.hasActiveOrders && !_isTrackingInitialized) {
      setState(() {
        _isTrackingInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _orderTrackingService.removeListener(_onServiceChanged);
    _orderTrackingService.stopTracking();
    super.dispose();
  }

  void _initializeOrderTracking() async {
    print('🚀 Initializing order tracking...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      print(
          '🔍 Auth state: isLoggedIn=${authProvider.isLoggedIn}, user=${authProvider.user?.id}');
      if (authProvider.isLoggedIn && authProvider.user != null) {
        print('🔍 Starting tracking for user: ${authProvider.user!.id}');
        await _orderTrackingService.startTracking(authProvider.user!.id);
        print('🔍 Tracking initialized, setting state...');
        setState(() {
          _isTrackingInitialized = true;
        });
        print(
            '🔍 State updated: _isTrackingInitialized=$_isTrackingInitialized');
      } else {
        print('❌ User not logged in, skipping tracking initialization');
      }
    });
  }

  void _handleNavigation(BuildContext context, String serviceType) {
    switch (serviceType) {
      case 'Delivery':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MenuScreenWithLocation()),
        );
        break;
      case 'Dine-In':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DineInPage()),
        );
        break;
      case 'Takeaway':
        // Open the menu directly in Takeaway mode
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const MenuScreenWithLocation(mode: OrderMode.takeaway)),
        );
        break;
    }
  }

  void _showOrderTrackingModal() {
    print('🛵 Order tracking button clicked!');
    print(
        '🔍 Service state: hasActiveOrders=${_orderTrackingService.hasActiveOrders}, count=${_orderTrackingService.activeOrderCount}');
    final activeOrders = _orderTrackingService.activeOrders;
    print('📋 Active orders count: ${activeOrders.length}');
    print('📋 Active orders details: $activeOrders');

    if (activeOrders.isEmpty) {
      print('❌ No active orders found');
      // Show a test dialog anyway
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Active Orders'),
          content: const Text('You have no active orders to track.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    // Show the first active order (you can modify this to show a list)
    final order = activeOrders.first;
    print('📦 Showing order: ${order.id}, Status: ${order.status}');

    // Show enhanced order status modal
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Order details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.attach_money,
                      'Total Amount',
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.location_on,
                      'Delivery Address',
                      order.deliveryAddress,
                      Colors.blue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // You can add more actions here like calling restaurant
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Track Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Colors.orange;
      case 'ready for pickup':
        return Colors.blue;
      case 'out for delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'preparing':
        return Icons.restaurant;
      case 'ready for pickup':
        return Icons.store;
      case 'out for delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // Simple suggestion banner to go to role dashboard

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final double horizontalPadding = constraints.maxWidth < 720
                ? 12
                : constraints.maxWidth < 1100
                    ? 20
                    : 0;
            // REPLACE THE OLD SingleChildScrollView WIDGET WITH THIS NEW ONE
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  // CHANGED: Added top padding to push content below the header.
                  // The header is about 88px tall, so 100px provides nice spacing.
                  top: 100,
                ),
                child: Column(
                  children: [
                    ServiceSelectionCarousel(
                      onOrderNow: () => _handleNavigation(context, 'Delivery'),
                      onExplore: () => _handleNavigation(context, 'Dine-In'),
                      onPickup: () => _handleNavigation(context, 'Takeaway'),
                    ),
                    if (authProvider.isLoggedIn) _RoleQuickAccess(),

                    // Continuing the home_screen.dart sections
                    _MenuCategoryCarousel(),
                    const AboutSection(),
                    const AiCulinaryCuratorSection(),
                    const CulinaryPhilosophySection(),
                    const FooterWidget(),
                  ],
                ),
              ),
            );
          }),

          // Fixed header with integrated navigation at the very top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const HeaderWidget(),
          ),

          // Order tracking button
          if (_isTrackingInitialized && authProvider.isLoggedIn)
            ChangeNotifierProvider.value(
              value: _orderTrackingService,
              child: Consumer<OrderTrackingService>(
                builder: (context, orderService, child) {
                  print(
                      '🔄 Consumer rebuild: count=${orderService.activeOrderCount}, hasOrders=${orderService.hasActiveOrders}');
                  return OrderTrackingButton(
                    onTap: _showOrderTrackingModal,
                    orderCount: orderService.activeOrderCount,
                    isVisible: orderService.hasActiveOrders,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleQuickAccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Debug information
    print('=== ROLE DEBUG INFO ===');
    print('User: ${auth.user?.name}');
    print('Email: ${auth.user?.email}');
    print('Role: ${auth.user?.role}');
    print('isAdmin: ${auth.isAdmin}');
    print('isManager: ${auth.isManager}');
    print('isEmployee: ${auth.isEmployee}');
    print('isDelivery: ${auth.isDelivery}');
    print('isKitchen: ${auth.isKitchen}');
    print('isWaiter: ${auth.isWaiter}');
    print('======================');

    String? route;
    String? buttonText;

    if (auth.isAdmin) {
      route = '/admin_dashboard';
      buttonText = 'Go to Admin Dashboard';
    } else if (auth.isManager) {
      route = '/manager_dashboard';
      buttonText = 'Go to Manager Dashboard';
    } else if (auth.isKitchen) {
      route = '/kitchen_dashboard';
      buttonText = 'Go to Kitchen Dashboard';
    } else if (auth.isDelivery) {
      route = '/delivery_dashboard';
      buttonText = 'Go to Delivery Dashboard';
    } else if (auth.isEmployee || auth.isWaiter) {
      route = auth.isWaiter ? '/waiter_dashboard' : '/employee_dashboard';
      buttonText =
          auth.isWaiter ? 'Go to Waiter Dashboard' : 'Go to Employee Dashboard';
    }

    if (route == null) {
      // Show debug info for users without specific roles
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Debug Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('User: ${auth.user?.name ?? "Not logged in"}'),
              Text('Role: ${auth.user?.role ?? "No role"}'),
              Text('isManager: ${auth.isManager}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => auth.refreshUserProfile(),
                      child: const Text('Refresh User Profile'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/debug_user_role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Debug Role'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, route!),
          icon: const Icon(Icons.dashboard_customize),
          label: Text(buttonText!),
        ),
      ),
    );
  }
}

class _MenuCategoryCarousel extends StatefulWidget {
  const _MenuCategoryCarousel();

  @override
  State<_MenuCategoryCarousel> createState() => _MenuCategoryCarouselState();
}

class _MenuCategoryCarouselState extends State<_MenuCategoryCarousel> {
  List<MenuCategory> categories = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentScrollIndex = 0; // mapped to original categories length
  int _hoveredIndex = -1;
  static const double _itemExtent = 160.0; // 140 width + 20 separator

  // Removed emoji mapping - using animated arrows instead

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _startAutoScroll();

    // Add scroll listener to track position and ensure smooth looping
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.offset;

        // Update current index based on scroll position
        _currentScrollIndex = (currentOffset / 160.0).round();
        if (_currentScrollIndex >= categories.length) {
          _currentScrollIndex = categories.length - 1;
        }

        // Ensure we stay within bounds
        if (_currentScrollIndex < 0) {
          _currentScrollIndex = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final fetchedCategories = await _apiService.fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
      );
      setState(() {
        categories = fetchedCategories;
        _isLoading = false;
      });
      // Center the list to the middle block to enable seamless infinite loop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && categories.isNotEmpty) {
          _scrollController.jumpTo(categories.length * _itemExtent);
        }
      });
    } catch (e) {
      // Fallback to default categories if API fails
      setState(() {
        categories = [
          MenuCategory(id: -1, name: 'Appetizers', items: const []),
          MenuCategory(id: -1, name: 'Soups & Salads', items: const []),
          MenuCategory(id: -1, name: 'Pizzas (11-inch)', items: const []),
          MenuCategory(id: -1, name: 'Pasta', items: const []),
          MenuCategory(id: -1, name: 'Sandwiches & Wraps', items: const []),
          MenuCategory(id: -1, name: 'Main Course - Indian', items: const []),
          MenuCategory(id: -1, name: 'Main Course - Global', items: const []),
          MenuCategory(id: -1, name: 'Desserts', items: const []),
          MenuCategory(id: -1, name: 'Beverages', items: const []),
        ];
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && categories.isNotEmpty) {
          _scrollController.jumpTo(categories.length * _itemExtent);
        }
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _autoScrollToNext();
      }
    });
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void _autoScrollToNext() {
    if (_scrollController.hasClients && categories.isNotEmpty) {
      final double current = _scrollController.offset;
      double target = current + _itemExtent;

      // If we're near the far right end of the tripled list, jump back by one block
      final double rightThreshold = (categories.length * 2 - 2) * _itemExtent;
      if (target > rightThreshold) {
        // Jump back by one full block (length * itemExtent) before animating
        final double jumped = current - (categories.length * _itemExtent);
        _scrollController.jumpTo(jumped);
        target = jumped + _itemExtent;
      }

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );

      // Update mapped index to the base categories list
      final int virtualIndex = (target / _itemExtent).round();
      _currentScrollIndex = virtualIndex % categories.length;
    }
  }

  void scrollLeft() {
    if (_scrollController.hasClients && categories.isNotEmpty) {
      final double current = _scrollController.offset;
      double target = current - _itemExtent;

      // If we're near the far left, jump forward by one block before animating
      final double leftThreshold = (_itemExtent * 1);
      if (target < leftThreshold) {
        final double jumped = current + (categories.length * _itemExtent);
        _scrollController.jumpTo(jumped);
        target = jumped - _itemExtent;
      }

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      final int virtualIndex = (target / _itemExtent).round();
      _currentScrollIndex =
          (virtualIndex % categories.length + categories.length) %
              categories.length;
    }
    _resetAutoScrollTimer();
  }

  void scrollRight() {
    if (_scrollController.hasClients && categories.isNotEmpty) {
      final double current = _scrollController.offset;
      double target = current + _itemExtent;

      final double rightThreshold = (categories.length * 2 - 2) * _itemExtent;
      if (target > rightThreshold) {
        final double jumped = current - (categories.length * _itemExtent);
        _scrollController.jumpTo(jumped);
        target = jumped + _itemExtent;
      }

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      final int virtualIndex = (target / _itemExtent).round();
      _currentScrollIndex = virtualIndex % categories.length;
    }
    _resetAutoScrollTimer();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Text('Menu Categories',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor),
            )
          else
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left,
                      size: 32,
                      color: isDark ? Colors.white70 : Colors.black87),
                  onPressed: scrollLeft,
                ),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          categories.length * 3, // Triple for infinite loop
                      separatorBuilder: (_, __) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        final actualIndex = index % categories.length;
                        final name = categories[actualIndex].name;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MenuScreenWithLocation(
                                    initialCategory: name),
                              ),
                            );
                          },
                          child: MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredIndex = actualIndex),
                            onExit: (_) => setState(() => _hoveredIndex = -1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              decoration: BoxDecoration(
                                color: _hoveredIndex == actualIndex
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.2)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.06)
                                        : Colors.white.withOpacity(0.7)),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _hoveredIndex == actualIndex
                                      ? Theme.of(context).primaryColor
                                      : Colors.white
                                          .withOpacity(isDark ? 0.12 : 0.2),
                                  width: _hoveredIndex == actualIndex ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _hoveredIndex == actualIndex
                                        ? Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3)
                                        : Colors.black
                                            .withOpacity(isDark ? 0.5 : 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Animated arrow icon instead of emoji
                                    AnimatedRotation(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      turns: _hoveredIndex == actualIndex
                                          ? 0.25
                                          : 0.0,
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 32,
                                        color: _hoveredIndex == actualIndex
                                            ? Colors.black
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Nunito',
                                        color: _hoveredIndex == actualIndex
                                            ? Colors.black
                                            : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right,
                      size: 32,
                      color: isDark ? Colors.white70 : Colors.black87),
                  onPressed: scrollRight,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
// REPLACE the entire old ServiceSelectionCarousel class with this new one.

class ServiceSelectionCarousel extends StatefulWidget {
  final VoidCallback onOrderNow;
  final VoidCallback onExplore;
  final VoidCallback onPickup;

  const ServiceSelectionCarousel({
    super.key,
    required this.onOrderNow,
    required this.onExplore,
    required this.onPickup,
  });

  @override
  State<ServiceSelectionCarousel> createState() =>
      _ServiceSelectionCarouselState();
}

class _ServiceSelectionCarouselState extends State<ServiceSelectionCarousel> {
  int _selectedIndex = 1;
  Timer? _autoScrollTimer;
  bool _isHoveringSelectedCard = false;

  late final List<Map<String, dynamic>> _cardData;

  // This helper method is no longer needed as we are adding real navigation.
  // void _showPlaceholderSnackBar(...) { ... }

  @override
  void initState() {
    super.initState();

    // CHANGED: All button actions are now mapped to navigation calls.
    // The original logic for the 3 main buttons is retained.
    _cardData = [
      // Delivery Card Data
      {
        'id': 0,
        'icon': Icons.delivery_dining_rounded,
        'title': 'Delivery',
        'buttons': [
          {
            'text': 'Order Now',
            'action': widget.onOrderNow, // Original logic retained
          },
          {
            'text': 'Meal Subscription',
            'action': () => Navigator.pushNamed(context, '/meal-subscription')
          },
          {
            'text': 'Track Order',
            'action': () => Navigator.pushNamed(context, '/track-order')
          },
        ]
      },
      // Dine-In Card Data
      {
        'id': 1,
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Dine-In',
        'buttons': [
          {
            'text': 'Reserve Table',
            'action': () => Navigator.pushNamed(context, '/reserve-table')
          },
          {
            'text': 'Order from Table',
            'action': () => Navigator.pushNamed(context, '/order-from-table')
          },
          {
            'text': 'Explore Menu',
            'action': widget.onExplore, // Original logic retained
          },
        ]
      },
      // Takeaway Card Data
      {
        'id': 2,
        'icon': Icons.shopping_bag_rounded,
        'title': 'Takeaway',
        'buttons': [
          {
            'text': 'Pickup',
            'action': widget.onPickup, // Original logic retained
          },
          {
            'text': 'Pre-Order',
            'action': () => Navigator.pushNamed(context, '/pre-order')
          },
          {
            'text': 'Favorites',
            'action': () => Navigator.pushNamed(context, '/favorites')
          },
        ]
      }
    ];

    // Start auto-scroll timer
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        _autoScrollToNext();
      }
    });
  }

  void _autoScrollToNext() {
    // Only auto-scroll if not hovering over the selected card
    if (!_isHoveringSelectedCard) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _cardData.length;
      });
    }
  }

  void _onCardTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Reset auto-scroll timer when user interacts
    _startAutoScroll();
  }

  Matrix4 _getTransform(int index, double screenWidth) {
    final double horizontalTranslation = screenWidth * 0.4;
    const double scale = 0.8;
    const double rotation = 0.05; // Small rotation for depth effect

    // Sequential/rotational transition logic based on the CSS pattern
    if (_selectedIndex == 0) {
      // Delivery selected
      if (index == 0) {
        // Current card (Delivery)
        return Matrix4.identity()
          ..scale(1.0)
          ..rotateZ(0.0);
      } else if (index == 1) {
        // Next card (Dine-In) - moves to right
        return Matrix4.identity()
          ..translate(horizontalTranslation)
          ..scale(scale)
          ..rotateZ(rotation);
      } else {
        // Previous card (Takeaway) - moves to left
        return Matrix4.identity()
          ..translate(-horizontalTranslation)
          ..scale(scale)
          ..rotateZ(-rotation);
      }
    } else if (_selectedIndex == 1) {
      // Dine-In selected
      if (index == 1) {
        // Current card (Dine-In)
        return Matrix4.identity()
          ..scale(1.0)
          ..rotateZ(0.0);
      } else if (index == 2) {
        // Next card (Takeaway) - moves to right
        return Matrix4.identity()
          ..translate(horizontalTranslation)
          ..scale(scale)
          ..rotateZ(rotation);
      } else {
        // Previous card (Delivery) - moves to left
        return Matrix4.identity()
          ..translate(-horizontalTranslation)
          ..scale(scale)
          ..rotateZ(-rotation);
      }
    } else {
      // Takeaway selected
      if (index == 2) {
        // Current card (Takeaway)
        return Matrix4.identity()
          ..scale(1.0)
          ..rotateZ(0.0);
      } else if (index == 0) {
        // Next card (Delivery) - moves to right
        return Matrix4.identity()
          ..translate(horizontalTranslation)
          ..scale(scale)
          ..rotateZ(rotation);
      } else {
        // Previous card (Dine-In) - moves to left
        return Matrix4.identity()
          ..translate(-horizontalTranslation)
          ..scale(scale)
          ..rotateZ(-rotation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const double headerHeight = 135;

    return Container(
      height: screenHeight - headerHeight,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_cardData.length, (index) {
              final bool isSelected = _selectedIndex == index;
              final data = _cardData[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Text(
                      data['title'],
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 28,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(_cardData.length, (index) {
                  final card = _cardData[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOutCubic,
                    transform: _getTransform(index, screenWidth),
                    transformAlignment: Alignment.center,
                    child: MouseRegion(
                      onEnter: (_) => setState(() =>
                          _isHoveringSelectedCard = index == _selectedIndex),
                      onExit: (_) =>
                          setState(() => _isHoveringSelectedCard = false),
                      child: GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 800),
                          opacity: index == _selectedIndex ? 1.0 : 0.4,
                          child: SizedBox(
                            width: screenWidth * 0.5,
                            child: Container(
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: index == _selectedIndex
                                      ? theme.primaryColor
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.3 : 0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Animated veggie background only for selected card
                                  if (index == _selectedIndex)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: const AnimatedVeggieBackground(),
                                    ),
                                  // Soft overlay for readability
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      color: (isDark
                                          ? Colors.black.withOpacity(0.20)
                                          : Colors.white.withOpacity(0.20)),
                                    ),
                                  ),
                                  // Foreground content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24, horizontal: 16),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        AnimatedScale(
                                          scale: index == _selectedIndex
                                              ? 1.1
                                              : 0.9,
                                          duration:
                                              const Duration(milliseconds: 800),
                                          child: AnimatedRotation(
                                            turns: index == _selectedIndex
                                                ? 0.0
                                                : 0.05,
                                            duration: const Duration(
                                                milliseconds: 1000),
                                            child: Icon(card['icon'],
                                                size: 48,
                                                color: theme.primaryColor),
                                          ),
                                        ),
                                        AnimatedScale(
                                          scale: index == _selectedIndex
                                              ? 1.0
                                              : 0.9,
                                          duration:
                                              const Duration(milliseconds: 800),
                                          child: Text(
                                            card['title'],
                                            style: theme.textTheme.displayLarge
                                                ?.copyWith(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ),
                                        Column(
                                          children: (card['buttons']
                                                  as List<Map<String, dynamic>>)
                                              .map((buttonData) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: _AnimatedButton(
                                                onPressed: buttonData['action']
                                                    as VoidCallback,
                                                text: buttonData['text'],
                                                isDark: isDark,
                                                theme: theme,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isDark;
  final ThemeData theme;

  const _AnimatedButton({
    required this.onPressed,
    required this.text,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textShadowAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 300.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _textShadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color get _buttonColor =>
      widget.isDark ? Colors.lightGreen : const Color(0xFF2E7D32);
  Color get _accentColor =>
      widget.isDark ? const Color(0xFF388E3C) : Colors.lightGreen;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 200, // Reduced width as requested
              height: 48,
              decoration: BoxDecoration(
                color: _isHovered ? _accentColor : _buttonColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(_isHovered ? 0.5 : 0.3),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: Offset(0, _isHovered ? 6 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Animated background circle - no small dot, starts from 0
                    Positioned(
                      left: 20,
                      bottom: 0,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Button text
                    Center(
                      child: AnimatedBuilder(
                        animation: _textShadowAnimation,
                        builder: (context, child) {
                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _isHovered ? 17 : 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                              shadows: [
                                Shadow(
                                  color: _accentColor.withOpacity(0.8),
                                  offset: Offset(
                                    3 - (1 * _textShadowAnimation.value),
                                    5 - (3 * _textShadowAnimation.value),
                                  ),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(widget.text),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
