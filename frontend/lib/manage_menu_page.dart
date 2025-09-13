// lib/manage_menu_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'add_edit_menu_item_page.dart';

class ManageMenuPage extends StatefulWidget {
  final VoidCallback? onMenuUpdated;
  final VoidCallback? onCategoryUpdated;

  const ManageMenuPage({
    super.key,
    this.onMenuUpdated,
    this.onCategoryUpdated,
  });

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<MenuCategory> _allMenuCategories = [];
  List<MenuCategory> _filteredMenuCategories = [];
  Set<int> _expandedCategories = {}; // Track which categories are expanded
  bool _isLoading = false;
  int? _selectedCategoryId; // when set, show detail view

  @override
  void initState() {
    super.initState();
    _loadMenuCategories();
    _searchController.addListener(_filterMenuCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMenuCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch both menu categories (with items) and all categories (including empty ones)
      final menuCategories = await _apiService.fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
      );

      final allCategories = await _apiService.getCategories();

      // Create a map of menu categories by ID for quick lookup
      final menuCategoriesMap = {
        for (var category in menuCategories) category.id: category
      };

      // Merge all categories with menu data, creating empty categories for those without items
      final mergedCategories = allCategories.map((categoryData) {
        final categoryId = categoryData['id'] as int;
        final categoryName = categoryData['name'] as String;

        // If this category has menu items, use the menu category data
        if (menuCategoriesMap.containsKey(categoryId)) {
          return menuCategoriesMap[categoryId]!;
        } else {
          // Create an empty category
          return MenuCategory(
            id: categoryId,
            name: categoryName,
            items: [],
          );
        }
      }).toList();

      setState(() {
        _allMenuCategories = mergedCategories;
        _filteredMenuCategories = mergedCategories;
        // Start with all categories collapsed by default
        _expandedCategories.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading menu items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterMenuCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMenuCategories = _allMenuCategories;
        // Keep current expansion state when search is cleared
        // Don't auto-expand all categories
      } else {
        _filteredMenuCategories = _allMenuCategories
            .map((category) {
              final filteredItems = category.items.where((item) {
                return item.name.toLowerCase().contains(query) ||
                    item.description.toLowerCase().contains(query);
              }).toList();

              return MenuCategory(
                id: category.id,
                name: category.name,
                items: filteredItems,
              );
            })
            .where((category) => category.items.isNotEmpty)
            .toList();
        // Expand all categories that have search results
        _expandedCategories =
            Set.from(_filteredMenuCategories.map((cat) => cat.id));
      }
    });
  }

  void _expandAllCategories() {
    setState(() {
      _expandedCategories =
          Set.from(_filteredMenuCategories.map((cat) => cat.id));
    });
  }

  void _collapseAllCategories() {
    setState(() {
      _expandedCategories.clear();
    });
  }

  void _toggleItemAvailability(MenuItem item) async {
    try {
      print('Toggling availability for item: ${item.name} (ID: ${item.id})');

      await _apiService.updateMenuItemAvailability(item.id, !item.isAvailable);

      print('Availability updated successfully, refreshing menu items...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${item.name} is now ${!item.isAvailable ? 'available' : 'unavailable'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _loadMenuCategories();
      widget.onMenuUpdated?.call();
    } catch (e) {
      print('Error updating availability: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getAvailabilityColor(bool isAvailable) {
    return isAvailable ? Colors.green : Colors.red;
  }

  void _addNewItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditMenuItemPage(
          onItemSaved: () {
            _loadMenuCategories();
            widget.onMenuUpdated?.call();
          },
          onCategoryUpdated: () {
            _loadMenuCategories();
            widget.onCategoryUpdated?.call();
          },
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add New Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the name for the new category:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  hintText: 'Category name...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) =>
                    _addNewCategory(categoryController.text.trim()),
              ),
            ],
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
                _addNewCategory(categoryController.text.trim());
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Create',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _addNewCategory(String categoryName) async {
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.createCategory(categoryName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$categoryName" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadMenuCategories();
      widget.onCategoryUpdated?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCategory(MenuCategory category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${category.name}"?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (category.items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This category contains ${category.items.length} menu item${category.items.length == 1 ? '' : 's'}. All menu items will be deleted first, then the category.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This category is empty and can be safely deleted.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                Navigator.of(context).pop();
                _confirmDeleteCategory(category);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Delete',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(MenuCategory category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Backend will handle deleting menu items automatically
      await _apiService.deleteCategory(category.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Category "${category.name}" and all its items deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadMenuCategories();
      widget.onMenuUpdated?.call();
      widget.onCategoryUpdated?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete category: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _confirmDeleteCategory(category),
          ),
        ),
      );
    }
  }

  void _editItem(MenuItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditMenuItemPage(
          menuItem: item,
          onItemSaved: () {
            _loadMenuCategories();
            widget.onMenuUpdated?.call();
          },
          onCategoryUpdated: () {
            _loadMenuCategories();
            widget.onCategoryUpdated?.call();
          },
        ),
      ),
    );
  }

  void _deleteItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Menu Item'),
          content: Text(
            'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmDeleteItem(item);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteItem(MenuItem item) async {
    try {
      print('Starting delete process for item: ${item.name} (ID: ${item.id})');

      await _apiService.deleteMenuItem(item.id);
      print('API call completed successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _loadMenuCategories();
      widget.onMenuUpdated?.call();
      print('Delete process completed successfully');
    } catch (e) {
      print('Error during delete process: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete item: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _confirmDeleteItem(item),
          ),
        ),
      );
    }
  }

  String _getCategoryIcon(String categoryName) {
    final categoryIcons = {
      'Appetizers': 'restaurant',
      'Soups & Salads': 'soup_kitchen',
      'Pizzas (11-inch)': 'local_pizza',
      'Pasta': 'ramen_dining',
      'Sandwiches & Wraps': 'lunch_dining',
      'Main Course - Indian': 'emoji_food_beverage',
      'Main Course - Global': 'public',
      'Desserts': 'cake',
      'Beverages': 'local_drink',
    };
    return categoryIcons[categoryName] ?? 'restaurant';
  }

  Color _getCategoryColor(String categoryName) {
    final categoryColors = {
      'Appetizers': Colors.orange,
      'Soups & Salads': Colors.lightGreen,
      'Pizzas (11-inch)': Colors.red,
      'Pasta': Colors.amber,
      'Sandwiches & Wraps': Colors.brown,
      'Main Course - Indian': Colors.deepOrange,
      'Main Course - Global': Colors.indigo,
      'Desserts': Colors.pink,
      'Beverages': Colors.blue,
    };
    return categoryColors[categoryName] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredMenuCategories.fold<int>(
        0, (sum, category) => sum + category.items.length);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage menu items and availability',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Search, Refresh, and Add Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search menu items by name or description...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadMenuCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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

          const SizedBox(height: 16),

          // Expand/Collapse Controls
          Row(
            children: [
              Text(
                '$totalItems menu item${totalItems == 1 ? '' : 's'} found in ${_filteredMenuCategories.length} categor${_filteredMenuCategories.length == 1 ? 'y' : 'ies'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _expandAllCategories,
                icon: const Icon(Icons.expand_more, size: 16),
                label: const Text('Expand All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _collapseAllCategories,
                icon: const Icon(Icons.expand_less, size: 16),
                label: const Text('Collapse All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading menu items...'),
                      ],
                    ),
                  )
                : _filteredMenuCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No menu items found matching your search'
                                  : 'No menu items found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : (_selectedCategoryId != null
                        ? _buildCategoryDetail(_filteredMenuCategories
                            .firstWhere((c) => c.id == _selectedCategoryId))
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildCategorizedMenuItems(),
                                if (_expandedCategories.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _buildExpandedSections(),
                                ]
                              ],
                            ),
                          )),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorizedMenuItems() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount:
              _filteredMenuCategories.length + 1, // +1 for Add Category card
          itemBuilder: (context, index) {
            if (index == _filteredMenuCategories.length) {
              return _buildAddCategoryCard();
            }
            return _buildCategoryCard(_filteredMenuCategories[index]);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(MenuCategory category) {
    final categoryColor = _getCategoryColor(category.name);
    final isExpanded = _expandedCategories.contains(category.id);
    final availableCount = category.items.where((i) => i.isAvailable).length;

    return _HoverableCategoryCard(
      category: category,
      categoryColor: categoryColor,
      isExpanded: isExpanded,
      availableCount: availableCount,
      onTap: () {
        setState(() {
          _selectedCategoryId = category.id;
        });
      },
      onDelete: () => _deleteCategory(category),
    );
  }

  Widget _buildAddCategoryCard() {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(isHovered ? 0.5 : 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                  blurRadius: isHovered ? 20 : 10,
                  offset: const Offset(0, 2),
                ),
                if (isHovered)
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showAddCategoryDialog,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add Category',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create new category',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
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

  Widget _buildExpandedSections() {
    print('Building expanded sections...');
    print('Expanded categories set: $_expandedCategories');

    final expandedCategories = _filteredMenuCategories
        .where((c) => _expandedCategories.contains(c.id))
        .toList();

    print('Found ${expandedCategories.length} expanded categories to render');
    for (final cat in expandedCategories) {
      print(
          'Rendering expanded section for: ${cat.name} (ID: ${cat.id}) with ${cat.items.length} items');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in expandedCategories) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(cat.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getCategoryIcon(cat.name),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${cat.name} • ${cat.items.length} items',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxis = _getCrossAxisCount(constraints.maxWidth);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxis,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
                ),
                itemCount: cat.items.length,
                itemBuilder: (context, i) => _buildMenuItemCard(cat.items[i]),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getChildAspectRatio(double width) {
    // Provide a bit more vertical space to avoid overflow of card content
    if (width > 1200) return 0.9; // taller cards on large screens
    if (width > 900) return 0.85;
    if (width > 600) return 0.8;
    return 0.75;
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHovered
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.grey[200]!,
                width: isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isHovered ? 0.15 : 0.05),
                  blurRadius: isHovered ? 15 : 5,
                  offset: const Offset(0, 2),
                ),
                if (isHovered)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      color: Colors.grey[300],
                    ),
                    child: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[600],
                                  size: 40,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.restaurant,
                            color: Colors.grey[600],
                            size: 40,
                          ),
                  ),
                ),

                // Item Details
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Item Description
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Price and Availability
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getAvailabilityColor(item.isAvailable)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.isAvailable ? 'Available' : 'Unavailable',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _getAvailabilityColor(item.isAvailable),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Dietary Tags
                        Wrap(
                          spacing: 4,
                          children: [
                            if (item.isVegan)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.lightGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Vegan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.lightGreen[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (item.isGlutenFree)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'GF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (!item.containsNuts)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Nut-Free',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Switch(
                                value: item.isAvailable,
                                onChanged: (value) =>
                                    _toggleItemAvailability(item),
                                thumbColor: WidgetStateProperty.resolveWith(
                                    (states) => Colors.white),
                                trackColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.selected)
                                            ? Colors.green
                                            : Colors.grey.shade300),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _editItem(item);
                                    break;
                                  case 'delete':
                                    _deleteItem(item);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              child: const Icon(Icons.more_vert, size: 20),
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
        );
      },
    );
  }

  // Category detail drill-in view
  Widget _buildCategoryDetail(MenuCategory category) {
    final categoryColor = _getCategoryColor(category.name);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to categories'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_getCategoryIcon(category.name),
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: categoryColor),
                      ),
                      Text(
                          '${category.items.length} items • ${category.items.where((i) => i.isAvailable).length} available',
                          style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
                ),
                itemCount:
                    category.items.length + 1, // +1 for Add Menu Item card
                itemBuilder: (context, index) {
                  if (index == category.items.length) {
                    return _buildAddMenuItemCard(category);
                  }
                  return _buildMenuItemCard(category.items[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenuItemCard(MenuCategory category) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(isHovered ? 0.5 : 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                  blurRadius: isHovered ? 20 : 10,
                  offset: const Offset(0, 2),
                ),
                if (isHovered)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showAddMenuItemDialog(category),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add Menu Item',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add to ${category.name}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
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

  void _showAddMenuItemDialog(MenuCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditMenuItemPage(
          onItemSaved: () {
            _loadMenuCategories();
            widget.onMenuUpdated?.call();
          },
          onCategoryUpdated: () {
            _loadMenuCategories();
            widget.onCategoryUpdated?.call();
          },
        ),
      ),
    );
  }
}

class _HoverableCategoryCard extends StatefulWidget {
  final MenuCategory category;
  final Color categoryColor;
  final bool isExpanded;
  final int availableCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HoverableCategoryCard({
    required this.category,
    required this.categoryColor,
    required this.isExpanded,
    required this.availableCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_HoverableCategoryCard> createState() => _HoverableCategoryCardState();
}

class _HoverableCategoryCardState extends State<_HoverableCategoryCard> {
  bool isHovered = false;

  String _getCategoryIcon(String categoryName) {
    final categoryIcons = {
      'Appetizers': 'restaurant',
      'Soups & Salads': 'soup_kitchen',
      'Pizzas (11-inch)': 'local_pizza',
      'Pasta': 'ramen_dining',
      'Sandwiches & Wraps': 'lunch_dining',
      'Main Course - Indian': 'emoji_food_beverage',
      'Main Course - Global': 'public',
      'Desserts': 'cake',
      'Beverages': 'local_drink',
    };
    return categoryIcons[categoryName] ?? 'restaurant';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
              blurRadius: isHovered ? 20 : (widget.isExpanded ? 14 : 10),
              offset: const Offset(0, 2),
            ),
            if (isHovered)
              BoxShadow(
                color: widget.categoryColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.categoryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _getCategoryIcon(widget.category.name),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.categoryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.category.items.length} items',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.availableCount} available',
                            style: TextStyle(
                              color: widget.categoryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: widget.categoryColor,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'delete':
                            widget.onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Category',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
