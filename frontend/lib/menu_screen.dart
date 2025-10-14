// lib/menu_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'api_service.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets/header_widget.dart';
import 'cart_screen.dart';
import 'takeaway_checkout_page.dart';
import 'models.dart';

import 'auth_provider.dart';

class MenuScreen extends StatefulWidget {
  final String? tableSessionId;
  final String? initialCategory;
  final int? initialItemId;
  final OrderMode mode;

  const MenuScreen({
    super.key,
    this.tableSessionId,
    this.initialCategory,
    this.initialItemId,
    this.mode = OrderMode.delivery,
  });

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  Future<List<MenuCategory>>? _menuFuture;
  int _selectedCategoryIndex = 0;
  bool _isVegOnly = false;
  bool _isBestseller = false;
  bool _isChefSpl = false;
  bool _isSeasonal = false;
  String _searchQuery = '';
  Timer? _debounce;
  bool _isSearching = false;
  bool _didJumpToInitialCategory = false;
  bool _didOpenInitialItem = false;

  // --- NEW SCROLL & KEY VARIABLES ---
  final ScrollController _menuScrollController = ScrollController();
  final Map<int, GlobalKey> _categoryKeys = {};
  bool _isScrollingProgrammatically = false;
  // Left category list helpers
  final ScrollController _leftCategoryScrollController = ScrollController();
  final Map<int, GlobalKey> _leftCategoryKeys = {};
  // --- END ---

  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Animation controllers (can be simplified later if not needed)
  late AnimationController _fadeController;

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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();

    _loadMenu();
    _searchController.addListener(_onSearchChanged);

    // Add the listener for the menu scroll controller
    _menuScrollController.addListener(_onMenuScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _fadeController.dispose();
    _menuScrollController.removeListener(_onMenuScroll); // Remove listener
    _menuScrollController.dispose(); // Dispose controller
    _leftCategoryScrollController.dispose();
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
      _menuFuture = _apiService
          .fetchMenu(
        vegOnly: _isVegOnly,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
        isBestseller: _isBestseller ? true : null,
        isChefSpl: _isChefSpl ? true : null,
        isSeasonal: _isSeasonal ? true : null,
        searchQuery: _searchQuery,
      )
          .then((categories) async {
        // Merge in any categories that exist in the DB but currently have no items
        try {
          final rawCats = await _apiService.getCategories();
          final existingNames =
              categories.map((c) => c.name.toLowerCase()).toSet();
          for (final c in rawCats) {
            final name = (c['name'] ?? c['category_name'] ?? '').toString();
            if (name.isEmpty) continue;
            if (!existingNames.contains(name.toLowerCase())) {
              categories.add(MenuCategory(
                  id: c['id'] is int ? c['id'] as int : -1,
                  name: name,
                  items: const []));
            }
          }
        } catch (_) {}
        return categories;
      });
      _selectedCategoryIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 75),
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
                if (widget.initialCategory != null &&
                    !_didJumpToInitialCategory) {
                  final idx = menuCategories.indexWhere((c) =>
                      c.name.toLowerCase() ==
                      widget.initialCategory!.toLowerCase());
                  if (idx != -1 && idx != _selectedCategoryIndex) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToCategory(idx);
                    });
                    _didJumpToInitialCategory = true;
                  }
                }
                // If an initial item id is provided, open its details popup once
                if (widget.initialItemId != null && !_didOpenInitialItem) {
                  for (final category in menuCategories) {
                    final match = category.items.firstWhere(
                      (it) => it.id == widget.initialItemId,
                      orElse: () => MenuItem(
                        id: -1,
                        name: '',
                        description: '',
                        price: 0,
                        imageUrl: '',
                        isAvailable: true,
                        isVegan: false,
                        isGlutenFree: false,
                        containsNuts: false,
                      ),
                    );
                    if (match.id != -1) {
                      // Scroll to the category first for context
                      final idx = menuCategories.indexOf(category);
                      if (idx != -1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToCategory(idx);
                        });
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showMenuItemDetails(match);
                      });
                      _didOpenInitialItem = true;
                      break;
                    }
                  }
                }
                for (int i = 0; i < menuCategories.length; i++) {
                  _categoryKeys.putIfAbsent(i, () => GlobalKey());
                  _leftCategoryKeys.putIfAbsent(i, () => GlobalKey());
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ## CHANGE 1: Left panel is now wrapped in the glass container ##
                    _buildGlassContainer(
                      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                      dense: true,
                      child: _buildLeftCategoryList(menuCategories),
                    ),

                    // ## CHANGE 2: Right panel is also wrapped in the glass container ##
                    Expanded(
                      child: _buildGlassContainer(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        dense: true,
                        child: _searchQuery.length >= 3
                            ? _buildSearchResults(menuCategories)
                            : _buildRightMenuList(menuCategories),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(
              active: HeaderActive.menu,
              showBack: true,
              orderMode: widget.mode,
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

  Widget _buildGlassContainer(
      {required Widget child, required EdgeInsets margin, bool dense = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.hardEdge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
          child: Container(
            decoration: BoxDecoration(
              color: dense
                  ? (isDark
                      ? Colors.black.withOpacity(0.72)
                      : Colors.white.withOpacity(0.97))
                  : (isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.white.withOpacity(0.9)),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: dense
                    ? (isDark
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.45))
                    : (isDark
                        ? Colors.white.withOpacity(0.22)
                        : Colors.white.withOpacity(0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // A new method to encapsulate the header/search bar
  Widget _buildHeader() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Menu',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 24)),
          Row(
            children: [
              // Search Field
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSearching ? 250 : 0,
                child: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search for dishes...',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      )
                    : null,
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isSearching = !_isSearching);
                  if (!_isSearching) _searchController.clear();
                },
                icon: Icon(_isSearching ? Icons.close : Icons.search),
              ),
              // Filter button moved to the left panel header
              // Cart Icon (reusing your existing logic)
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                        icon: const Icon(Icons.shopping_cart_outlined),
                      ),
                      if (cartProvider.items.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              '${cartProvider.items.length}',
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // Builds the scrollable category list on the left
  Widget _buildLeftCategoryList(List<MenuCategory> categories) {
    return Container(
      width: 280,
      color: Colors.transparent, // Changed from Theme.of(context).cardColor
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                tooltip: 'Filters',
                onPressed: () => _showFilterDialog(context),
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: _leftCategoryScrollController,
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  key: _leftCategoryKeys[index],
                  child: _buildCategoryItem(
                    category,
                    index,
                    isSelected: index == _selectedCategoryIndex,
                    onTap: () => _scrollToCategory(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Builds the main scrollable menu on the right, grouped by category
  Widget _buildRightMenuList(List<MenuCategory> categories) {
    // ## FIX: Corrected the variable name here ##
    final selectedCategory = categories[_selectedCategoryIndex];

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      controller: _menuScrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 60,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark
                      ? Colors.black.withOpacity(0.35)
                      : Colors.white.withOpacity(0.65)),
                  border: Border(
                    bottom: BorderSide(
                      color: (isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06)),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            selectedCategory.name,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 22,
                ),
          ),
          titleSpacing: 24,
          actions: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSearching ? 250 : 0,
              child: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search in menu...',
                          filled: true,
                          fillColor: (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.85)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    )
                  : null,
            ),
            IconButton(
              onPressed: () {
                setState(() => _isSearching = !_isSearching);
                if (!_isSearching) _searchController.clear();
              },
              icon: Icon(_isSearching ? Icons.close : Icons.search),
            ),
            // Filter button moved to the left panel header
            // Cart Icon (reusing your existing logic)
            Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                    if (cartProvider.items.isNotEmpty)
                      Positioned(
                        right: 4,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${cartProvider.items.length}',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        for (int i = 0; i < categories.length; i++) ...[
          SliverToBoxAdapter(
            key: _categoryKeys[i],
            child: Container(height: 0.1),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 340,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = categories[i].items[index];
                  return _buildMenuItemCard(item);
                },
                childCount: categories[i].items.length,
              ),
            ),
          ),
          if (i < categories.length - 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: _buildCategorySeparator(),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }

  // Builds the view for search results
  Widget _buildSearchResults(List<MenuCategory> allCategories) {
    final allItems = allCategories.expand((c) => c.items).toList();
    final filteredItems = allItems.where((item) {
      final q = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();

    if (filteredItems.isEmpty) return _buildEmptyState();

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 420,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(filteredItems[index]);
      },
    );
  }

  Widget _buildCategoryItem(
    MenuCategory category,
    int index, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Reduced margin from 8 to 4
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.black87)
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showMenuItemDetails(item),
            splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
            highlightColor: Colors.transparent,
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
                  // Image section with veg/non-veg badge
                  Stack(
                    children: [
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
                                color: Theme.of(context).custom.primaryLight,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.restaurant,
                                  size: 50,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _buildVegBadge(item),
                      ),
                    ],
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
                                    color:
                                        isDark ? Colors.white : Colors.black87,
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

                          // Tags are shown only inside the details dialog

                          const SizedBox(height: 4),

                          // Description
                          Expanded(
                            child: Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600,
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
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

                                  final quantity =
                                      cart.getItemQuantity(item.id);
                                  return quantity == 0
                                      ? MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (widget.mode ==
                                                  OrderMode.takeaway) {
                                                _showTakeawayItemDetail(
                                                    context, item);
                                              } else {
                                                cart.addItem(item);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
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

  Widget _buildVegBadge(MenuItem item) {
    final bool veg = item.isVegan || item.isVegetarian;
    final Color color =
        veg ? Colors.greenAccent.shade400 : Colors.redAccent.shade200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
        ],
      ),
    );
  }

  Widget _buildNutritionChips(MenuItem item) {
    final String name = item.name.toLowerCase();
    final int seed = (item.name.hashCode & 0x7fffffff);

    int rand(int base, int spread, int offset) {
      return base + ((seed + offset) % spread);
    }

    // Baselines by category
    int protein;
    int carbs;
    int fat;
    int calories;

    if (name.contains('salad')) {
      protein = rand(4, 6, 3);
      carbs = rand(10, 15, 7);
      fat = rand(4, 6, 11);
      calories = rand(120, 60, 13);
    } else if (name.contains('soup')) {
      protein = rand(3, 5, 3);
      carbs = rand(8, 12, 7);
      fat = rand(2, 4, 11);
      calories = rand(110, 50, 13);
    } else if (name.contains('pizza')) {
      protein = rand(9, 8, 3);
      carbs = rand(48, 20, 7);
      fat = rand(12, 10, 11);
      calories = rand(420, 120, 13);
    } else if (name.contains('pasta')) {
      protein = rand(8, 6, 3);
      carbs = rand(55, 18, 7);
      fat = rand(10, 8, 11);
      calories = rand(390, 100, 13);
    } else if (name.contains('biryani')) {
      protein = rand(12, 8, 3);
      carbs = rand(60, 20, 7);
      fat = rand(14, 10, 11);
      calories = rand(520, 140, 13);
    } else if (name.contains('kebab') ||
        name.contains('tikka') ||
        name.contains('skewer')) {
      protein = rand(16, 10, 3);
      carbs = rand(6, 8, 7);
      fat = rand(12, 8, 11);
      calories = rand(280, 80, 13);
    } else if (name.contains('wrap') ||
        name.contains('sandwich') ||
        name.contains('burger')) {
      protein = rand(14, 8, 3);
      carbs = rand(40, 18, 7);
      fat = rand(12, 10, 11);
      calories = rand(450, 120, 13);
    } else if (name.contains('noodle')) {
      protein = rand(10, 6, 3);
      carbs = rand(58, 18, 7);
      fat = rand(9, 8, 11);
      calories = rand(420, 110, 13);
    } else if (name.contains('roll') ||
        name.contains('fry') ||
        name.contains('fried')) {
      protein = rand(6, 6, 3);
      carbs = rand(30, 16, 7);
      fat = rand(15, 12, 11);
      calories = rand(360, 110, 13);
    } else {
      protein = rand(8, 8, 3);
      carbs = rand(35, 20, 7);
      fat = rand(9, 10, 11);
      calories = rand(320, 120, 13);
    }

    // Vegetarian items slightly adjust macros
    if (item.isVegetarian) {
      protein = (protein * 0.9).round();
      fat = (fat * 0.9).round();
      carbs = (carbs * 1.05).round();
    }

    Widget chip(String label, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.7)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Protein: ${protein}g', Colors.teal),
        chip('Carbs: ${carbs}g', Colors.indigo),
        chip('Fat: ${fat}g', Colors.orange),
        chip('~${calories} kcal', Colors.pinkAccent),
      ],
    );
  }

  // Decorative, thin and modern animated separator between categories
  Widget _buildCategorySeparator() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark ? Colors.white24 : Colors.black12;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      base,
                      Theme.of(context).primaryColor,
                      base,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
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

  // Builds a richer, AI-like long description that varies per item.
  String _getEnhancedDescription(MenuItem item) {
    final String name = item.name.toLowerCase();
    final int seed = (item.name.hashCode & 0x7fffffff);

    String pick(List<String> options, int offset) {
      final int idx = (seed + offset) % options.length;
      return options[idx];
    }

    String type;
    if (name.contains('soup'))
      type = 'soup';
    else if (name.contains('pizza'))
      type = 'pizza';
    else if (name.contains('pasta'))
      type = 'pasta';
    else if (name.contains('biryani'))
      type = 'biryani';
    else if (name.contains('curry'))
      type = 'curry';
    else if (name.contains('salad'))
      type = 'salad';
    else if (name.contains('wrap') || name.contains('sandwich'))
      type = 'sandwich';
    else if (name.contains('kebab') ||
        name.contains('tikka') ||
        name.contains('skewer'))
      type = 'tandoor';
    else if (name.contains('roll') || name.contains('spring'))
      type = 'fried_snack';
    else if (name.contains('noodle'))
      type = 'noodles';
    else if (name.contains('burger'))
      type = 'burger';
    else if (name.contains('dessert') ||
        name.contains('brownie') ||
        name.contains('cake') ||
        name.contains('ice cream'))
      type = 'dessert';
    else
      type = 'general';

    final openings = {
      'soup': [
        'A comforting bowl with ',
        'A steaming ladle of ',
        'A soul-warming serving of '
      ],
      'pizza': [
        'An artisanal base crowned with ',
        'Hand-tossed and stone-baked, showcasing ',
        'Crisp-edged crust layered with '
      ],
      'pasta': [
        'Al dente pasta coated in ',
        'A trattoria-style plate with ',
        'Silky sauce embracing '
      ],
      'biryani': [
        'Fragrant basmati layered with ',
        'Slow-cooked rice perfumed by ',
        'Dum-style grains infused with '
      ],
      'curry': [
        'A slow-simmered curry boasting ',
        'Creamy gravy enriched with ',
        'A hearty preparation with '
      ],
      'salad': [
        'A bright, garden-fresh medley of ',
        'Crisp, refreshing greens with ',
        'A light, zesty bowl highlighting '
      ],
      'sandwich': [
        'A generously-stacked bite with ',
        'Toasted layers bringing together ',
        'A café-style classic packed with '
      ],
      'tandoor': [
        'Char-smoked and spice-marinated, featuring ',
        'Tandoor-kissed notes of ',
        'Flame-grilled skewers with '
      ],
      'fried_snack': [
        'Golden-fried and crisp, delivering ',
        'A crunchy, addictive snack with ',
        'Light yet indulgent bites featuring '
      ],
      'noodles': [
        'Wok-tossed noodles scented with ',
        'Street-style stir-fry built on ',
        'A lively toss of noodles with '
      ],
      'burger': [
        'A juicy, stacked burger with ',
        'Griddle-seared patty paired with ',
        'Soft buns embracing '
      ],
      'dessert': [
        'A decadent finale of ',
        'An indulgent dessert showcasing ',
        'A sweet treat layered with '
      ],
      'general': [
        'A thoughtfully prepared plate celebrating ',
        'A restaurant-style creation highlighting ',
        'A balanced preparation built around '
      ],
    };

    final flavor = {
      'soup': ['peppery warmth', 'ginger–garlic depth', 'umami richness'],
      'pizza': [
        'slow-cooked tomato brightness',
        'wood-fired aromas',
        'balanced cheese savouriness'
      ],
      'pasta': [
        'silky, well-seasoned sauce',
        'buttery richness',
        'herb-lifted creaminess'
      ],
      'biryani': [
        'layered spices and saffron perfume',
        'caramelized onions and warm aromatics',
        'cardamom and bay depth'
      ],
      'curry': [
        'rounded spices with gentle heat',
        'slow-simmered complexity',
        'comforting warmth'
      ],
      'salad': [
        'zesty dressing and fresh herbs',
        'citrus lift with clean crunch',
        'light vinaigrette notes'
      ],
      'sandwich': [
        'tangy condiments and balanced seasoning',
        'melty, savoury layers',
        'peppery bite with creamy undertones'
      ],
      'tandoor': [
        'smoky spice and yoghurt tenderness',
        'charred edges with aromatic masalas',
        'bright spices with a hint of lemon'
      ],
      'fried_snack': [
        'crackling crunch and savoury spice',
        'light batter with bold seasoning',
        'crisp exterior and juicy centre'
      ],
      'noodles': [
        'soy–garlic umami and chilli heat',
        'wok hei smokiness',
        'tangy-savoury balance'
      ],
      'burger': [
        'juicy savouriness and tangy sauces',
        'smoky sear with creamy balance',
        'pickled brightness and melty cheese'
      ],
      'dessert': [
        'rich sweetness and aromatic notes',
        'cocoa depth with a silky finish',
        'buttery warmth and gentle vanilla'
      ],
      'general': [
        'balanced seasoning and clean flavours',
        'aromatic spices with rounded heat',
        'fresh herbs and savoury depth'
      ],
    };

    final texture = {
      'soup': [
        'light, steamy broth',
        'velvety body',
        'hearty, sip-friendly texture'
      ],
      'pizza': [
        'crisp yet airy crust',
        'chewy centre with crisp edges',
        'thin, crackly base'
      ],
      'pasta': [
        'al dente bite',
        'silky coating',
        'creamy cling on each strand'
      ],
      'biryani': [
        'fluffy, separate grains',
        'tender layers',
        'aromatic, well-steamed rice'
      ],
      'curry': [
        'velvety gravy',
        'rich, spoon-coating texture',
        'homestyle thickness'
      ],
      'salad': ['crisp leaves', 'juicy bites', 'light crunch'],
      'sandwich': ['toasty bite', 'generous layering', 'soft crunch'],
      'tandoor': [
        'char-kissed surface',
        'succulent interior',
        'grill-seared juiciness'
      ],
      'fried_snack': [
        'shatteringly crisp shell',
        'light crunch',
        'golden, airy batter'
      ],
      'noodles': ['springy noodles', 'bouncy strands', 'tender chew'],
      'burger': ['soft buns', 'juicy centre', 'satisfying stack'],
      'dessert': ['soft crumb', 'silky mouthfeel', 'creamy indulgence'],
      'general': ['pleasing bite', 'well-balanced body', 'comforting feel'],
    };

    final finishes = {
      'soup': [
        'a clean, appetising finish',
        'gentle warmth that lingers',
        'a soothing aftertaste'
      ],
      'pizza': [
        'an authentic pizzeria-style finish',
        'a satisfying, cheesy finish',
        'an aromatic close'
      ],
      'pasta': [
        'a bright, clean finish',
        'a buttery, comforting close',
        'a satisfying, saucy finale'
      ],
      'biryani': [
        'an irresistible dum aroma',
        'a regal, celebratory finish',
        'lingering warmth'
      ],
      'curry': [
        'a homely, satisfying finish',
        'a round, mellow aftertaste',
        'comforting warmth'
      ],
      'salad': [
        'a refreshing finale',
        'a crisp, clean finish',
        'an uplifting close'
      ],
      'sandwich': [
        'a snack-perfect finish',
        'a café-style close',
        'a hearty finale'
      ],
      'tandoor': [
        'a smoky, zesty finish',
        'a lemony, uplifting close',
        'a festive grill note'
      ],
      'fried_snack': [
        'a craveable finish',
        'a light, moreish close',
        'a snackable finale'
      ],
      'noodles': [
        'a lively street-style finish',
        'a savoury, umami close',
        'a peppery finale'
      ],
      'burger': [
        'a diner-style finish',
        'a saucy, satisfying close',
        'a hearty finale'
      ],
      'dessert': [
        'a decadent finale',
        'a sweet, satisfying close',
        'a gentle, creamy finish'
      ],
      'general': [
        'a balanced finish',
        'a flavourful close',
        'a satisfying finale'
      ],
    };

    final String open = pick(openings[type]!, 1);
    final String flav = pick(flavor[type]!, 7);
    final String text = pick(texture[type]!, 13);
    final String end = pick(finishes[type]!, 29);

    final String vegNote = item.isVegetarian
        ? 'vegetarian preparation'
        : 'non‑vegetarian specialty';
    final List<String> badges = [];
    if (item.isBestseller) badges.add('bestseller');
    if (item.isChefSpecial) badges.add('chef special');
    if (item.isSeasonal) badges.add('seasonal');
    final String tag = badges.isEmpty ? '' : ' • ' + badges.join(' • ');

    final String lead = item.description.isNotEmpty
        ? item.description
        : 'A thoughtfully prepared ${item.name}.';

    return '$lead\n\n$open$flav, $text, and $end — a $vegNote$tag.';
  }

  List<Widget> _buildTagChips(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<Widget> chips = [];

    Widget buildChip(String label, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    if (item.isBestseller) {
      chips.add(
          buildChip('Bestseller', Colors.orange, Icons.local_fire_department));
    }
    if (item.isChefSpecial) {
      chips.add(buildChip('Chef Special', Colors.purple, Icons.star));
    }
    if (item.isSeasonal) {
      chips.add(buildChip('Seasonal', Colors.green, Icons.eco));
    }
    return chips;
  }

  void _showMenuItemDetails(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Main content with proper spacing for close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 60, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header section with image and basic info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image in top-left corner
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color:
                                        Theme.of(context).custom.primaryLight,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 40,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title, price, and details section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Price badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Tags
                                if (item.isBestseller ||
                                    item.isChefSpecial ||
                                    item.isSeasonal)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _buildTagChips(item),
                                  ),
                                const SizedBox(height: 12),
                                // Quick details row
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _buildQuickDetail(
                                      Icons.people,
                                      'Serves 1',
                                      isDark,
                                    ),
                                    _buildQuickDetail(
                                      Icons.access_time,
                                      '15-20 mins',
                                      isDark,
                                    ),
                                    _buildQuickDetail(
                                      Icons.circle,
                                      item.isVegetarian
                                          ? 'Vegetarian'
                                          : 'Non-Vegetarian',
                                      isDark,
                                      color: item.isVegetarian
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description.isNotEmpty
                                  ? item.description
                                  : 'A delicious ${item.name} prepared with fresh ingredients and authentic flavors.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nutrition section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nutrition (per serving)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildNutritionChips(item),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<CartProvider>(
                              builder: (context, cart, child) {
                                if (!item.isAvailable) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
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
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          elevation: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shopping_cart_outlined,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Add to Cart',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _buildQuantityCounter(item);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Consumer<FavoritesProvider>(
                            builder: (context, favoritesProvider, child) {
                              final isFavorited =
                                  favoritesProvider.isFavorite(item.id);
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isFavorited
                                      ? Colors.red.withOpacity(0.1)
                                      : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isFavorited
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      final authProvider =
                                          Provider.of<AuthProvider>(context,
                                              listen: false);
                                      if (authProvider.isLoggedIn) {
                                        favoritesProvider.toggleFavorite(item);
                                      } else {
                                        showLoginPrompt(context);
                                      }
                                    },
                                    child: Icon(
                                      isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorited
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Close button positioned in top-right corner
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.grey.shade700,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickDetail(IconData icon, String text, bool isDark,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? (isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCounter(MenuItem item) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.getItemQuantity(item.id);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: Icon(Icons.remove,
                  size: 16, color: Theme.of(context).primaryColor),
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
              icon: Icon(Icons.add,
                  size: 16, color: Theme.of(context).primaryColor),
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
              color: Theme.of(context).primaryColor,
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
                      color: Theme.of(context).primaryColor,
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
                    'Menu Filters',
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
                      title: 'Bestseller',
                      subtitle: 'Show only bestseller dishes',
                      icon: Icons.star,
                      value: _isBestseller,
                      onChanged: (value) {
                        setDialogState(() {
                          _isBestseller = value;
                        });
                      },
                    ),
                    _buildFilterTile(
                      title: 'Chef Special',
                      subtitle: 'Show only chef special dishes',
                      icon: Icons.restaurant_menu,
                      value: _isChefSpl,
                      onChanged: (value) {
                        setDialogState(() {
                          _isChefSpl = value;
                        });
                      },
                    ),
                    _buildFilterTile(
                      title: 'Seasonal',
                      subtitle: 'Show only seasonal dishes',
                      icon: Icons.wb_sunny,
                      value: _isSeasonal,
                      onChanged: (value) {
                        setDialogState(() {
                          _isSeasonal = value;
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
                    backgroundColor: Theme.of(context).primaryColor,
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
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Theme.of(context).primaryColor : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              color:
                  value ? Theme.of(context).primaryColor : Colors.grey.shade600,
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
            return Theme.of(context)
                .primaryColor; // Theme color for the toggle dot
          }
          return Colors.grey.shade400; // Default grey for untoggled state
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).primaryColor.withOpacity(0.5);
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
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
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    value: 'half',
                                    groupValue: selectedPortion,
                                    onChanged: (v) {
                                      setSheetState(() => selectedPortion = v!);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                    title: Row(
                                      children: [
                                        Icon(Icons.local_dining,
                                            color: onSurface.withOpacity(0.8),
                                            size: 18),
                                        const SizedBox(width: 10),
                                        Text('Half',
                                            style: TextStyle(
                                                color: onSurface,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    secondary: Text(
                                        '₹${(item.price * 0.8).round()}',
                                        style: TextStyle(color: subText)),
                                  ),
                                  const Divider(height: 0),
                                  RadioListTile<String>(
                                    value: 'full',
                                    groupValue: selectedPortion,
                                    onChanged: (v) {
                                      setSheetState(() => selectedPortion = v!);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                    title: Row(
                                      children: [
                                        Icon(Icons.local_dining_outlined,
                                            color: onSurface.withOpacity(0.8),
                                            size: 18),
                                        const SizedBox(width: 10),
                                        Text('Full',
                                            style: TextStyle(
                                                color: onSurface,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    secondary: Text(
                                        '₹${item.price.toStringAsFixed(0)}',
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
                                    if (widget.mode == OrderMode.takeaway) {
                                      Provider.of<CartProvider>(context,
                                              listen: false)
                                          .addItem(item);
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TakeawayCheckoutPage(
                                              itemJustAdded: item),
                                        ),
                                      );
                                    } else {
                                      Provider.of<CartProvider>(context,
                                              listen: false)
                                          .addItem(item);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    widget.mode == OrderMode.takeaway
                                        ? 'Add to Takeaway'
                                        : 'Add Item to cart',
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
                      color: Theme.of(context).primaryColor,
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
                    Provider.of<CartProvider>(context, listen: false)
                        .addItem(item);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    widget.mode == OrderMode.takeaway
                        ? 'Add to Takeaway'
                        : 'Add to Cart',
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

  // ...WITH THIS NEW, CORRECTED METHOD
  void _onMenuScroll() {
    // If we are scrolling because a category was clicked, don't interfere.
    if (_isScrollingProgrammatically) return;

    // Determine which category header's top offset is currently at/above the viewport top.
    // This method is robust across slivers because it uses getOffsetToReveal.
    const threshold = kToolbarHeight + 10; // account for the pinned app bar
    final double currentOffset = _menuScrollController.offset + threshold;

    int? newIndex;
    for (final entry in _categoryKeys.entries) {
      final key = entry.value;
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final renderObject = ctx.findRenderObject();
      if (renderObject == null) continue;

      final viewport = RenderAbstractViewport.of(renderObject);
      if (viewport == null) continue;

      final reveal = viewport.getOffsetToReveal(renderObject, 0.0).offset;
      if (reveal <= currentOffset) {
        newIndex = entry.key;
      }
    }

    // If the scroll position has resulted in a new category being at the top,
    // update the state to rebuild the UI.
    if (newIndex != null && newIndex != _selectedCategoryIndex) {
      setState(() {
        _selectedCategoryIndex = newIndex!;
      });
      _scrollLeftListToIndex(_selectedCategoryIndex);
    }
  }

  // Takeaway-specific item detail modal
  void _showTakeawayItemDetail(BuildContext rootContext, MenuItem item) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.primaryColor),
                      ),
                      child: const Text(
                        'Takeaway',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: TextStyle(color: onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Provider.of<CartProvider>(context, listen: false)
                            .addItem(item);
                        Navigator.of(context).pop();
                        // Use rootContext to navigate after the dialog closes
                        Future.microtask(() {
                          Navigator.of(rootContext).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TakeawayCheckoutPage(itemJustAdded: item),
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Add to Takeaway'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Removed now that Add routes directly to checkout for Takeaway

  void _scrollToCategory(int index) {
    // Prevent the scroll listener from firing while we animate
    _isScrollingProgrammatically = true;
    setState(() {
      _selectedCategoryIndex = index;
    });

    final key = _categoryKeys[index];

    // This ensures the scrolling happens AFTER the screen has had a chance to update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key?.currentContext != null) {
        final ctx = key!.currentContext!;
        final renderObject = ctx.findRenderObject();
        if (renderObject != null) {
          final viewport = RenderAbstractViewport.of(renderObject);
          if (viewport != null) {
            final targetOffset =
                viewport.getOffsetToReveal(renderObject, 0.0).offset;
            _menuScrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            );
          } else {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              alignment: 0,
            );
          }
        }
      }
    });
    _scrollLeftListToIndex(index);

    // Allow the listener to resume after the scroll animation
    Future.delayed(const Duration(milliseconds: 700), () {
      _isScrollingProgrammatically = false;
    });
  }

  void _scrollLeftListToIndex(int index) {
    final key = _leftCategoryKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    } else {
      _leftCategoryScrollController.animateTo(
        index * 56.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
              color: Theme.of(context).primaryColor,
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
            backgroundColor: Theme.of(context).primaryColor,
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
          onPressed: () async {
            Navigator.of(ctx).pop();
            final result = await Navigator.pushNamed(context, '/login');
            // If login was successful, the user can now add to favorites
            if (result == true) {
              // The user is now logged in, they can retry their action
            }
          },
        ),
      ],
    ),
  );
}
