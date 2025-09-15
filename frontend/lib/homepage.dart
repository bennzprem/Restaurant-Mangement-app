import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'auth_provider.dart'; // keep your auth provider import
import 'menu_screen.dart';
import 'dine_in_page.dart';
import 'takeaway_page.dart';
import 'api_service.dart';
import 'models.dart';

import '../widgets/header_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/about_section.dart';
import '../widgets/ai_culinary_curator_section.dart';
import '../widgets/culinary_philosophy_section.dart';
import '../widgets/footer_widget.dart';

import 'theme.dart'; // Your AppTheme

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 0, // No top padding - content starts immediately after header
                ),
                child: Column(
                  children: [
                    HeroSection(
                      onOrderNow: () => _handleNavigation(context, 'Delivery'),
                      onExplore: () => _handleNavigation(context, 'Dine-In'),
                      onPickup: () => _handleNavigation(context, 'Takeaway'),
                    ),
                    if (authProvider.isLoggedIn) _RoleQuickAccess(),

                    // Continuing the home_screen.dart sections
                    _MenuCategoryCarousel(),
                    AboutSection(),
                    AiCulinaryCuratorSection(),
                    CulinaryPhilosophySection(),
                    FooterWidget(),
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
            child: HeaderWidget(active: HeaderActive.home),
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
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.customBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 16, color: AppTheme.customGrey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
            ],
          ),
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
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

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
      _currentScrollIndex = (virtualIndex % categories.length + categories.length) % categories.length;
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
                  color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          else
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left,
                      size: 32, color: isDark ? Colors.white70 : Colors.black87),
                  onPressed: scrollLeft,
                ),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        final name = categories[index].name;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MenuScreen(initialCategory: name),
                            ),
                          );
                        },
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = -1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              color: _hoveredIndex == index
                                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.white.withOpacity(0.7)),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _hoveredIndex == index
                                    ? Theme.of(context).primaryColor
                                    : Colors.white
                                        .withOpacity(isDark ? 0.12 : 0.2),
                                width: _hoveredIndex == index ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _hoveredIndex == index
                                      ? Theme.of(context).primaryColor.withOpacity(0.3)
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
                                    duration: const Duration(milliseconds: 300),
                                    turns: _hoveredIndex == index ? 0.25 : 0.0,
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 32,
                                      color: _hoveredIndex == index
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
                                      color: _hoveredIndex == index
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
                    size: 32, color: isDark ? Colors.white70 : Colors.black87),
                onPressed: scrollRight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
