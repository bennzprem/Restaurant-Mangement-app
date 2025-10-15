import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../widgets/header_widget.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/cart_screen.dart';

class SubscriptionComboPage extends StatefulWidget {
  const SubscriptionComboPage({super.key});

  @override
  State<SubscriptionComboPage> createState() => _SubscriptionComboPageState();
}

class _SubscriptionComboPageState extends State<SubscriptionComboPage> {
  int _selectedCategoryIndex = 0;
  final ApiService _apiService = ApiService();
  Future<List<MenuCategory>>? _menuFuture;
  String? _selectedRightCategoryName;
  final GlobalKey _headerTitleKey = GlobalKey();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> categories = const [
    {
      "title": "Smart Saver",
      "icon": Icons.calendar_view_week,
      "subtitle": "Save more with weekly smart plans"
    },
    {
      "title": "Hassle-Free Month", 
      "icon": Icons.calendar_month,
      "subtitle": "One-click meals for the whole month"
    },
    {
      "title": "Family Feast",
      "icon": Icons.family_restroom,
      "subtitle": "Big portions made for sharing"
    },
    {
      "title": "Workday Fuel",
      "icon": Icons.business_center,
      "subtitle": "Quick combos to power busy days"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleInitialCategory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleInitialCategory() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['initialCategory'] != null) {
      final initialCategory = args['initialCategory'] as String;
      final index = categories.indexWhere((cat) => cat['title'] == initialCategory);
      if (index != -1) {
        setState(() {
          _selectedCategoryIndex = index;
        });
      }
    }
  }

  Future<void> _loadMenu() async {
    try {
      final menu = await _apiService.fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
        subscriptionType: _subscriptionKeyForIndex(_selectedCategoryIndex),
      );
      setState(() {
        _menuFuture = Future.value(menu);
        _selectedRightCategoryName = menu.isNotEmpty ? menu.first.name : null;
      });
    } catch (e) {
      setState(() {
        _menuFuture = Future.error(e);
      });
    }
  }

  String? _subscriptionKeyForIndex(int index) {
    switch (index) {
      case 0:
        return 'weekly';
      case 1:
        return 'monthly';
      case 2:
        return 'family_pack';
      case 3:
        return 'office_lunch';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left category list
                    _buildGlassContainer(
                      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                      dense: true,
                      child: _buildLeftCategoryList(),
                    ),
                    
                    // Right menu items
                    Expanded(
                      child: _buildGlassContainer(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        dense: true,
                        child: _buildRightMenuList(menuCategories),
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
                  Navigator.of(context).pushReplacementNamed('/explore-menu');
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

  Widget _buildLeftCategoryList() {
    return Container(
      width: 280,
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscription & Combo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'Filters',
                onPressed: () => Navigator.pushNamed(context, '/menu'),
                icon: const Icon(Icons.filter_list),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryItem(
                  category,
                  index,
                  isSelected: index == _selectedCategoryIndex,
                  onTap: () async {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                    await _loadMenu();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    Map<String, dynamic> category,
    int index, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
            child: Row(
              children: [
                Icon(
                  category['icon'],
                  size: 20,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.black87)
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.black87)
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightMenuList(List<MenuCategory> menuCategories) {
    final selectedCategory = categories[_selectedCategoryIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableCategoryNames = menuCategories.map((c) => c.name).toList();
    final selectedRightName = _selectedRightCategoryName ?? (availableCategoryNames.isNotEmpty ? availableCategoryNames.first : null);
    final filteredItems = selectedRightName == null
        ? <MenuItem>[]
        : (menuCategories.firstWhere(
                (c) => c.name == selectedRightName,
                orElse: () => MenuCategory(id: -1, name: selectedRightName, items: const []))
            .items);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          actions: [],
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
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        selectedCategory['icon'],
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  if (selectedRightName != null) {
                                    Navigator.pushNamed(context, '/menu', arguments: {'initialCategory': selectedRightName});
                                  }
                                },
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: (Theme.of(context).textTheme.displayLarge ?? const TextStyle()).copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  child: Container(
                                    key: _headerTitleKey,
                                    child: Text(selectedRightName ?? 'Select Category'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (availableCategoryNames.isNotEmpty)
                              IconButton(
                                tooltip: 'Change category',
                                onPressed: () async {
                                  final RenderBox? box = _headerTitleKey.currentContext?.findRenderObject() as RenderBox?;
                                  final Offset pos = box?.localToGlobal(Offset.zero) ?? const Offset(200, 140);
                                  final Size size = box?.size ?? const Size(200, 24);
                                  final selected = await showMenu<String>(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      pos.dx,
                                      pos.dy + size.height + 6,
                                      pos.dx + size.width,
                                      0,
                                    ),
                                    items: [
                                      for (final name in availableCategoryNames)
                                        PopupMenuItem<String>(value: name, child: Text(name)),
                                    ],
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      _selectedRightCategoryName = selected;
                                    });
                                  }
                                },
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                       // Search and Cart icons (matching Signature Soups style)
                       const SizedBox(width: 8),
                       if (_isSearching) ...[
                         // Expanded search field
                         Container(
                           width: 320,
                           height: 40,
                           decoration: BoxDecoration(
                             color: Theme.of(context).scaffoldBackgroundColor,
                             borderRadius: BorderRadius.circular(30),
                           ),
                           child: Row(
                             children: [
                               Expanded(
                                 child: Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 14),
                                   child: TextField(
                                     controller: _searchController,
                                     decoration: const InputDecoration(
                                       hintText: 'Search items...',
                                       border: InputBorder.none,
                                       contentPadding: EdgeInsets.zero,
                                     ),
                                     onChanged: (_) => setState(() {}),
                                   ),
                                 ),
                               ),
                               IconButton(
                                 tooltip: 'Close search',
                                 onPressed: () {
                                   setState(() {
                                     _isSearching = false;
                                     _searchController.clear();
                                   });
                                 },
                                 icon: Icon(
                                   Icons.close,
                                   color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(width: 8),
                       ] else ...[
                         // Search icon (only visible when not searching)
                         IconButton(
                           tooltip: 'Search',
                           onPressed: () {
                             setState(() {
                               _isSearching = true;
                             });
                           },
                           icon: Icon(
                             Icons.search,
                             color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                           ),
                         ),
                         const SizedBox(width: 4),
                       ],
                       Consumer<CartProvider>(
                         builder: (context, cart, child) {
                           return Stack(
                             children: [
                               IconButton(
                                 tooltip: 'Cart',
                                 onPressed: () {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (context) => const CartScreen(),
                                     ),
                                   );
                                 },
                                 icon: Icon(
                                   Icons.shopping_cart_outlined,
                                   color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                 ),
                               ),
                               // Cart item count badge
                               if (cart.items.isNotEmpty)
                                 Positioned(
                                   right: 6,
                                   top: 6,
                                   child: Container(
                                     padding: const EdgeInsets.all(2),
                                     decoration: BoxDecoration(
                                       color: Colors.green,
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                     constraints: const BoxConstraints(
                                       minWidth: 16,
                                       minHeight: 16,
                                     ),
                                     child: Text(
                                       '${cart.items.length}',
                                       style: const TextStyle(
                                         color: Colors.white,
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
                ),
              ),
            ),
          ),
        ),
        if (filteredItems.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items found for ${selectedCategory['title']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredItems[index];
                  return _buildMenuItemCard(item);
                },
                childCount: filteredItems.length,
              ),
            ),
          ),
      ],
    );
  }

  List<MenuItem> _filterMenuItemsByCategory(List<MenuCategory> menuCategories, String categoryTitle) {
    List<MenuItem> allItems = [];
    for (var category in menuCategories) {
      allItems.addAll(category.items);
    }
    
    // Filter based on category title - you can customize this logic
    return allItems.where((item) {
      // Simple filtering - you can enhance this based on your data structure
      return item.name.toLowerCase().contains(categoryTitle.toLowerCase().split(' ')[0]) ||
             item.description.toLowerCase().contains(categoryTitle.toLowerCase().split(' ')[0]);
    }).toList();
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.restaurant,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final isFavorited = favoritesProvider.isFavorite(item.id);
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
                                  final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  if (authProvider.isLoggedIn) {
                                    Provider.of<FavoritesProvider>(
                                      context,
                                      listen: false,
                                    ).toggleFavorite(item);
                                  } else {
                                    _showLoginPrompt(context);
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
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Price and add to cart row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
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
                                    onPressed: () {
                                      cart.addItem(item);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                              : _buildQuantityCounter(item, cart);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityCounter(MenuItem item, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () => cart.removeSingleItem(item.id),
              icon: const Icon(Icons.remove, size: 16),
              color: Colors.black,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          Text(
            '${cart.getItemQuantity(item.id)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              onPressed: () => cart.addItem(item),
              icon: const Icon(Icons.add, size: 16),
              color: Colors.black,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to add items to favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMenu,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No menu items available'),
    );
  }
}