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
  bool _isBestseller = false;
  bool _isChefSpl = false;
  bool _isSeasonal = false;
  String _searchQuery = '';
  Timer? _debounce;
  bool _isSearching = false;
  bool _didJumpToInitialCategory = false;
  
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
  late Animation<double> _fadeAnimation;

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
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
          final existingNames = categories.map((c) => c.name.toLowerCase()).toSet();
          for (final c in rawCats) {
            final name = (c['name'] ?? c['category_name'] ?? '').toString();
            if (name.isEmpty) continue;
            if (!existingNames.contains(name.toLowerCase())) {
              categories.add(MenuCategory(id: c['id'] is int ? c['id'] as int : -1, name: name, items: const []));
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
              if (widget.initialCategory != null && !_didJumpToInitialCategory) {
                final idx = menuCategories.indexWhere((c) => c.name.toLowerCase() == widget.initialCategory!.toLowerCase());
                if (idx != -1 && idx != _selectedCategoryIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToCategory(idx);
                  });
                  _didJumpToInitialCategory = true;
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
Widget _buildGlassContainer({required Widget child, required EdgeInsets margin, bool dense = false}) {
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
              style:
                  Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
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
              IconButton(
                onPressed: () => _showFilterDialog(context),
                icon: const Icon(Icons.filter_list),
              ),
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
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${cartProvider.items.length}',
                              style: const TextStyle(color: Colors.black, fontSize: 10),
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
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.filter_list),
          ),
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
              mainAxisExtent: 300,
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
        mainAxisExtent: 300,
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

                              final quantity = cart.getItemQuantity(item.id);
                              return quantity == 0
                                  ? MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: ElevatedButton(
                                        onPressed: () => cart.addItem(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
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
                                child: Icon(
                                  Icons.restaurant,
                                  size: 50,
                                  color: Theme.of(context).primaryColor,
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
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
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
                                              backgroundColor: Theme.of(context).primaryColor,
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
              icon: Icon(Icons.remove, size: 16, color: Theme.of(context).primaryColor),
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
              icon: Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor),
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
              color: value ? Theme.of(context).primaryColor : Colors.grey.shade600,
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
            return Theme.of(context).primaryColor; // Theme color for the toggle dot
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
                                    activeColor: Theme.of(context).primaryColor,
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
                                    activeColor: Theme.of(context).primaryColor,
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
                                    backgroundColor: Theme.of(context).primaryColor,
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
                    Provider.of<CartProvider>(context, listen: false).addItem(item);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
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
          final targetOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;
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
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    ),
  );
}
