// lib/menu_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets/header_widget.dart';
import 'widgets/footer_widget.dart';

import 'auth_provider.dart';

class MenuScreen extends StatefulWidget {
  final String? tableSessionId;
  final String? initialCategory;

  const MenuScreen({
    super.key,
    this.tableSessionId,
    this.initialCategory,
  });

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  Future<List<MenuCategory>>? _menuFuture;
  int _selectedCategoryIndex = 0;
  bool _isVegOnly = false;
  bool _isVegan = false;
  bool _isGlutenFree = false;
  bool _isNutsFree = false;
  String _searchQuery = '';
  Timer? _debounce;
  bool _isSearching = false;
  bool _isCategorySidebarOpen = false;

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _sidebarController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _sidebarAnimation;

  final Map<String, String> categoryIcons = {
    'Appetizers': '🍽️',
    'Soups & Salads': '🥗',
    'Pizzas (11-inch)': '🍕',
    'Pasta': '🍝',
    'Sandwiches & Wraps': '🥪',
    'Main Course - Indian': '🥘',
    'Main Course - Global': '🌍',
    'Desserts': '🍰',
    'Beverages': '🥤',
  };

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _sidebarAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    _loadMenu();

    // Listen for category argument
    _menuFuture = _apiService.fetchMenu(
      vegOnly: _isVegOnly,
      veganOnly: _isVegan,
      glutenFreeOnly: _isGlutenFree,
      nutsFree: _isNutsFree,
      searchQuery: _searchQuery,
    );

    _menuFuture!.then((menuCategories) {
      if (widget.initialCategory != null) {
        final index =
            menuCategories.indexWhere((c) => c.name == widget.initialCategory);
        if (index != -1) {
          setState(() {
            _selectedCategoryIndex = index;
          });
        }
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _sidebarController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _loadMenu();
      }
    });
  }

  void _loadMenu() {
    setState(() {
      _menuFuture = _apiService.fetchMenu(
        vegOnly: _isVegOnly,
        veganOnly: _isVegan,
        glutenFreeOnly: _isGlutenFree,
        nutsFree: _isNutsFree,
        searchQuery: _searchQuery,
      );
      _selectedCategoryIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double wideLayoutThreshold = 800;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > wideLayoutThreshold;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      drawer: !isWide ? _buildDrawer() : null,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Space for fixed header
              const SizedBox(height: 75),

              // Menu content
              Expanded(
                child: FutureBuilder<List<MenuCategory>>(
                  future: _menuFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }
                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final menuCategories = snapshot.data!;
                    if (_selectedCategoryIndex >= menuCategories.length) {
                      _selectedCategoryIndex = 0;
                    }
                    final selectedCategory =
                        menuCategories[_selectedCategoryIndex];

                    return Stack(
                      children: [
                        // Main menu content
                        _buildMenuContent(selectedCategory, menuCategories),
                        
                        // Backdrop overlay when sidebar is open
                        if (_isCategorySidebarOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isCategorySidebarOpen = false;
                                });
                                _sidebarController.reverse();
                              },
                              child: Container(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        
                        // Sliding category sidebar
                        _buildSlidingSidebar(menuCategories),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Fixed header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(
              active: HeaderActive.menu,
              showBack: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return FutureBuilder<List<MenuCategory>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final menuCategories = snapshot.data!;
        return Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
            ),
            child: Column(
              children: [
                // Drawer header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.category,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Menu Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Categories list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: menuCategories.length,
                    itemBuilder: (context, index) {
                      final category = menuCategories[index];
                      return AnimatedBuilder(
                        animation: _slideController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0,
                                30 * (1 - _slideAnimation.value) * (index + 1)),
                            child: Opacity(
                              opacity: _slideAnimation.value,
                              child: _buildCategoryItem(
                                category,
                                index,
                                isSelected: index == _selectedCategoryIndex,
                                onTap: () {
                                  setState(
                                      () => _selectedCategoryIndex = index);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlidingSidebar(List<MenuCategory> menuCategories) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _sidebarAnimation,
      builder: (context, child) {
        return Positioned(
          left: _sidebarAnimation.value * 320, // Slide from left
          top: 0,
          bottom: 0,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAE952),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.category,
                        color: Colors.black,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isCategorySidebarOpen = false;
                          });
                          _sidebarController.reverse();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Categories list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: menuCategories.length,
                    itemBuilder: (context, index) {
                      final category = menuCategories[index];
                      return _buildCategoryItem(
                        category,
                        index,
                        isSelected: index == _selectedCategoryIndex,
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                            _isCategorySidebarOpen = false;
                          });
                          _sidebarController.reverse();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(List<MenuCategory> menuCategories) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(left: 16, top: 24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white10 : Colors.white.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.12 : 0.25)),
          ),
          child: Column(
            children: [
              // Heading that mirrors the selected category name
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    const Icon(Icons.category, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Categories',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Categories list (header removed per request)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: menuCategories.length,
                  itemBuilder: (context, index) {
                    final category = menuCategories[index];
                    return AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0,
                              20 * (1 - _slideAnimation.value) * (index + 1)),
                          child: Opacity(
                            opacity: _slideAnimation.value,
                            child: _buildCategoryItem(
                              category,
                              index,
                              isSelected: index == _selectedCategoryIndex,
                              onTap: () => setState(
                                  () => _selectedCategoryIndex = index),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    MenuCategory category,
    int index, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFDAE952) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? null
            : Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFDAE952).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  categoryIcons[category.name] ?? '🍴',
                  style: TextStyle(
                    fontSize: isSelected ? 22 : 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: isSelected ? 16 : 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.black
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        child: Text(category.name),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: isSelected ? 11 : 10,
                          color: isSelected
                              ? Colors.black87
                              : (isDark
                                  ? Colors.white70
                                  : Colors.grey.shade600),
                        ),
                        child: Text('${category.items.length} items'),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent(MenuCategory selectedCategory, List<MenuCategory> allCategories) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white10 : Colors.white.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.12 : 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header with category button on the left
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Category toggle button on the left
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _isCategorySidebarOpen = !_isCategorySidebarOpen;
                            });
                            if (_isCategorySidebarOpen) {
                              _sidebarController.forward();
                            } else {
                              _sidebarController.reverse();
                            }
                          },
                          icon: Icon(
                            Icons.menu,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryIcons[selectedCategory.name] ?? '🍴',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _searchQuery.length >= 3 ? 'Results' : selectedCategory.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.length >= 3
                                  ? '${allCategories.expand((c) => c.items).where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()) || item.description.toLowerCase().contains(_searchQuery.toLowerCase())).length} matching items'
                                  : '${selectedCategory.items.length} delicious items',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action icons with in-place search
                      Row(
                        children: [
                          // In-place search field
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: _isSearching ? 200 : 0,
                            height: 40,
                            child: _isSearching
                                ? Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFDAE952),
                                        width: 1.6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFDAE952).withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      onChanged: (value) {
                                        _debounce?.cancel();
                                        _debounce = Timer(const Duration(milliseconds: 300), () {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        });
                                      },
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search...',
                                        hintStyle: TextStyle(
                                          color: isDark ? Colors.white60 : Colors.black54,
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      textAlign: TextAlign.left,
                                      textAlignVertical: TextAlignVertical.center,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          // Search toggle icon
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isSearching = !_isSearching;
                                  if (!_isSearching) {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }
                                });
                              },
                              icon: Icon(
                                _isSearching ? Icons.close : Icons.search,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          // Filter icon
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: IconButton(
                              onPressed: () => _showFilterDialog(context),
                              icon: Icon(
                                Icons.filter_list,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          // Favorite icon (only when logged in)
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (authProvider.isLoggedIn) {
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: IconButton(
                                    onPressed: () {
                                      // Navigate to favorites or show favorites
                                      Navigator.pushNamed(context, '/favorites');
                                    },
                                    icon: Icon(
                                      Icons.favorite_border,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          // Cart icon
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return Stack(
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: IconButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/cart');
                                      },
                                      icon: Icon(
                                        Icons.shopping_cart_outlined,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ),
                                  if (cartProvider.items.isNotEmpty)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDAE952),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '${cartProvider.items.length}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // Menu items grid
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double cardWidth = 300;
                      final int crossAxisCount =
                          (constraints.maxWidth / cardWidth)
                              .floor()
                              .clamp(1, 4);

                      // Filter items based on search query (3+ characters) across ALL categories
                      final allItems = allCategories.expand((c) => c.items).toList();
                      final filteredItems = _searchQuery.length >= 3
                          ? allItems.where((item) {
                              final q = _searchQuery.toLowerCase();
                              return item.name.toLowerCase().contains(q) ||
                                     item.description.toLowerCase().contains(q);
                            }).toList()
                          : selectedCategory.items;

                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 300,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _fadeAnimation.value,
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: _buildMenuItemCard(filteredItems[index]),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showMenuItemDetails(item),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.12 : 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Image section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    item.isAvailable ? Colors.transparent : Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: Image.network(
                    item.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: AppTheme.primaryLight,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.restaurant,
                          size: 50,
                          color: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with favorite button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, child) {
                              final isFavorited =
                                  favoritesProvider.isFavorite(item.id);
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: IconButton(
                                    padding: const EdgeInsets.all(8),
                                    iconSize: 18,
                                    icon: Icon(
                                      isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorited
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      final authProvider =
                                          Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                      if (authProvider.isLoggedIn) {
                                        Provider.of<FavoritesProvider>(
                                          context,
                                          listen: false,
                                        ).toggleFavorite(item);
                                      } else {
                                        showLoginPrompt(context);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Description
                      Expanded(
                        child: Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Price and action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Consumer<CartProvider>(
                            builder: (context, cart, child) {
                              if (!item.isAvailable) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Unavailable',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }

                              final quantity = cart.getItemQuantity(item.id);
                              return quantity == 0
                                  ? MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: ElevatedButton(
                                        onPressed: () => _showAddToCartOptions(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Add',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _buildQuantityCounter(item);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  String _getEnhancedDescription(MenuItem item) {
    // AI-enhanced descriptions for better user experience
    final enhancedDescriptions = {
      'Spicy Pepperoni Pizza': 'A fiery masterpiece featuring premium pepperoni slices with a perfect blend of spices, topped with extra mozzarella cheese on our signature crispy crust. Each bite delivers an explosion of flavors that will satisfy your craving for authentic Italian-American cuisine.',
      'Mushroom & Truffle Oil Pizza': 'An elegant fusion of earthy mushrooms and luxurious truffle oil, creating a sophisticated flavor profile. This gourmet pizza features a medley of wild mushrooms, creamy cheese, and aromatic truffle oil drizzled over our artisanal crust.',
      'Paneer Tikka Skewers': 'Tender cubes of fresh paneer marinated in a rich blend of yogurt, aromatic spices, and herbs, then grilled to perfection alongside colorful bell peppers. These skewers offer a perfect balance of smoky flavors and creamy texture, making them an ideal appetizer or main course.',
      'Crispy Chilli Baby Corn': 'Golden-fried baby corn tossed in a tangy and spicy sauce with fresh bell peppers and onions. This popular Indo-Chinese dish offers the perfect combination of crunch and flavor, with a delightful balance of sweet, sour, and spicy notes.',
      'Spicy Prawn Aglio Olio': 'Succulent prawns sautéed with garlic, chili flakes, and fresh herbs in extra virgin olive oil, served over perfectly al dente pasta. This classic Italian dish delivers bold flavors with a hint of heat, showcasing the natural sweetness of fresh prawns.',
    };
    
    return enhancedDescriptions[item.name] ?? item.description;
  }

  void _showMenuItemDetails(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: Transform.translate(
            offset: const Offset(0, 60),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(
                  maxWidth: 800,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            item.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: AppTheme.primaryLight,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 50,
                                  color: AppTheme.primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                        // Scrollable Content
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Enhanced Description
                                Text(
                                  _getEnhancedDescription(item),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Serving info and dietary info
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: 16,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Serves 1',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Dietary Information',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            item.isVegan ? Icons.eco : Icons.eco_outlined,
                                            size: 16,
                                            color: item.isVegan ? Colors.green : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.isVegan ? 'Vegan' : 'Vegetarian',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? Colors.white70 : Colors.black54,
                                              fontWeight: item.isVegan ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.isGlutenFree) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.grain,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Gluten Free',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark ? Colors.white70 : Colors.black54,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (item.containsNuts) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.warning,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Contains Nuts',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark ? Colors.white70 : Colors.black54,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (!item.containsNuts) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Nuts Free',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark ? Colors.white70 : Colors.black54,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Actions moved to fixed footer
                              ],
                            ),
                          ),
                        ),
                        // Fixed footer to complete the card bottom
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Consumer<CartProvider>(
                                  builder: (context, cart, child) {
                                    if (!item.isAvailable) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Unavailable',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }
                                    final quantity = cart.getItemQuantity(item.id);
                                    return quantity == 0
                                        ? ElevatedButton(
                                            onPressed: () {
                                              _showAddToCartOptions(item);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text(
                                              'Add to Cart',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        : _buildQuantityCounter(item);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Consumer<FavoritesProvider>(
                                builder: (context, favoritesProvider, child) {
                                  final isFavorited = favoritesProvider.isFavorite(item.id);
                                  return IconButton(
                                    onPressed: () {
                                      final authProvider = Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                      if (authProvider.isLoggedIn) {
                                        favoritesProvider.toggleFavorite(item);
                                      } else {
                                        showLoginPrompt(context);
                                      }
                                    },
                                    icon: Icon(
                                      isFavorited ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorited ? Colors.red : Colors.grey,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              color: isDark ? Colors.black : Colors.black87,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityCounter(MenuItem item) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.getItemQuantity(item.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 16, color: AppTheme.primaryColor),
              onPressed: () => cart.removeSingleItem(item.id),
              splashRadius: 16,
              constraints: const BoxConstraints(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
              onPressed: () => cart.addItem(item),
              splashRadius: 16,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading delicious menu...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No menu items found for your filter.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAE952),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dietary Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterTile(
                      title: 'Vegetarian',
                      subtitle: 'Show only vegetarian dishes',
                      icon: Icons.eco,
                      value: _isVegOnly,
                      onChanged: (value) {
                        setDialogState(() {
                          _isVegOnly = value;
                        });
                      },
                    ),
                    _buildFilterTile(
                      title: 'Vegan',
                      subtitle: 'Show only vegan dishes',
                      icon: Icons.spa,
                      value: _isVegan,
                      onChanged: (value) {
                        setDialogState(() {
                          _isVegan = value;
                        });
                      },
                    ),
                    _buildFilterTile(
                      title: 'Gluten-Free',
                      subtitle: 'Show only gluten-free dishes',
                      icon: Icons.grain,
                      value: _isGlutenFree,
                      onChanged: (value) {
                        setDialogState(() {
                          _isGlutenFree = value;
                        });
                      },
                    ),
                    _buildFilterTile(
                      title: 'Nuts-Free',
                      subtitle: 'Show only nuts-free dishes',
                      icon: Icons.no_food,
                      value: _isNutsFree,
                      onChanged: (value) {
                        setDialogState(() {
                          _isNutsFree = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _loadMenu();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDAE952),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFDAE952).withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFFDAE952) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? const Color(0xFFDAE952) : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: value ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF9EAD3A); // Darker green for the toggle dot
          }
          return Colors.grey.shade400; // Default grey for untoggled state
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFDAE952).withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  void _showAddToCartOptions(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedPortion = 'full';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final Color surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final Color onSurface = isDark ? Colors.white : Colors.black87;
        final Color subText = isDark ? Colors.white70 : Colors.black54;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Customise as per your taste',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                )),
                            const SizedBox(height: 16),
                            Text('Quantity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                )),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    value: 'half',
                                    groupValue: selectedPortion,
                                    onChanged: (v) {
                                      setSheetState(() => selectedPortion = v!);
                                    },
                                    activeColor: const Color(0xFF9EAD3A),
                                    title: Row(
                                      children: [
                                        Icon(Icons.local_dining,
                                            color: onSurface.withOpacity(0.8), size: 18),
                                        const SizedBox(width: 10),
                                        Text('Half',
                                            style: TextStyle(
                                                color: onSurface, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    secondary: Text('₹${(item.price * 0.8).round()}',
                                        style: TextStyle(color: subText)),
                                  ),
                                  const Divider(height: 0),
                                  RadioListTile<String>(
                                    value: 'full',
                                    groupValue: selectedPortion,
                                    onChanged: (v) {
                                      setSheetState(() => selectedPortion = v!);
                                    },
                                    activeColor: const Color(0xFF9EAD3A),
                                    title: Row(
                                      children: [
                                        Icon(Icons.local_dining_outlined,
                                            color: onSurface.withOpacity(0.8), size: 18),
                                        const SizedBox(width: 10),
                                        Text('Full',
                                            style: TextStyle(
                                                color: onSurface, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    secondary: Text('₹${item.price.toStringAsFixed(0)}',
                                        style: TextStyle(color: subText)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '₹${selectedPortion == 'half' ? (item.price * 0.8).round() : item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Provider.of<CartProvider>(context, listen: false)
                                        .addItem(item);
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Item to cart',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAddToCartOptionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        onTap: onPressed,
      ),
    );
  }

  void _showCustomizationModal(MenuItem item) {
    showDialog(
      context: Navigator.of(context).overlay!.context!,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAE952),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Customize Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add customization options here
                    // For example, a dropdown for quantity, a checkbox for spice level, etc.
                    // This is a placeholder. In a real app, you'd have a form or multiple fields.
                    Text(
                      'Customization Options for ${item.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quantity: ${Provider.of<CartProvider>(context).getItemQuantity(item.id)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Spice Level: (Placeholder for a slider or dropdown)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notes: (Placeholder for a text field)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Logic to add customized item to cart
                    // This would involve creating a new MenuItem with customization options
                    // and adding it to the cart.
                    // For now, we'll just add it as is.
                    Provider.of<CartProvider>(context, listen: false).addItem(item);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDAE952),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

void showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDAE952),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.login,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Login Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: const Text(
        'You need to be logged in to add items to favorites.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDAE952),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'Login',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}
