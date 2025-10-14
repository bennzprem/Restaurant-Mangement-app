// lib/add_edit_menu_item_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'theme.dart';

class AddEditMenuItemPage extends StatefulWidget {
  final MenuItem? menuItem; // null for adding, MenuItem for editing
  final VoidCallback? onItemSaved;
  final VoidCallback? onCategoryUpdated;

  const AddEditMenuItemPage({
    super.key,
    this.menuItem,
    this.onItemSaved,
    this.onCategoryUpdated,
  });

  @override
  State<AddEditMenuItemPage> createState() => _AddEditMenuItemPageState();
}

class _AddEditMenuItemPageState extends State<AddEditMenuItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isAvailable = true;
  bool _isVegan = false;
  bool _isGlutenFree = false;
  bool _containsNuts = false;

  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isSaving = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // Load categories after a short delay to ensure the widget is fully initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.menuItem != null) {
      // Editing existing item
      _nameController.text = widget.menuItem!.name;
      _descriptionController.text = widget.menuItem!.description;
      _priceController.text = widget.menuItem!.price.toString();
      _imageUrlController.text = widget.menuItem!.imageUrl;
      _isAvailable = widget.menuItem!.isAvailable;
      _isVegan = widget.menuItem!.isVegan;
      _isGlutenFree = widget.menuItem!.isGlutenFree;
      _containsNuts = widget.menuItem!.containsNuts;
      // Note: We'll set category ID after loading categories
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting to load categories...');
      final categories = await _apiService.getCategories();
      print('DEBUG: Categories loaded successfully: ${categories.length}');

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      // Set the selected category for editing
      if (widget.menuItem != null && _categories.isNotEmpty) {
        // Find the category ID for the current menu item
        if (widget.menuItem!.categoryId != null) {
          _selectedCategoryId = widget.menuItem!.categoryId;
        } else {
          // Fallback to first category if no category is set
          final firstCategory = _categories.first;
          if (firstCategory['id'] != null) {
            _selectedCategoryId = firstCategory['id'];
          }
        }
      } else if (_categories.isNotEmpty) {
        final firstCategory = _categories.first;
        if (firstCategory['id'] != null) {
          _selectedCategoryId = firstCategory['id'];
        }
      }
    } catch (e) {
      print('DEBUG: Error loading categories: $e');
      if (!mounted) return;

      setState(() {
        _categories = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshCategories() async {
    await _loadCategories();
    widget.onCategoryUpdated?.call();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).custom.customBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).custom.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).custom.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).custom.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Theme.of(context).custom.customGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).custom.customBlack,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).custom.customGrey,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).custom.customLightGrey,
    );
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Theme.of(context).custom.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final price = double.parse(_priceController.text);

      if (widget.menuItem != null) {
        // Updating existing item
        await _apiService.updateMenuItem(
          id: widget.menuItem!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrl: _imageUrlController.text.trim(),
          isAvailable: _isAvailable,
          isVegan: _isVegan,
          isGlutenFree: _isGlutenFree,
          containsNuts: _containsNuts,
          categoryId: _selectedCategoryId!,
        );
      } else {
        // Creating new item
        await _apiService.createMenuItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrl: _imageUrlController.text.trim(),
          isAvailable: _isAvailable,
          isVegan: _isVegan,
          isGlutenFree: _isGlutenFree,
          containsNuts: _containsNuts,
          categoryId: _selectedCategoryId!,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.menuItem != null
              ? 'Menu item updated successfully!'
              : 'Menu item added successfully!'),
          backgroundColor: Theme.of(context).custom.successColor,
        ),
      );

      widget.onItemSaved?.call();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).custom.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check to prevent null errors during initialization
    try {
      print('DEBUG: Building AddEditMenuItemPage...');
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            widget.menuItem != null ? 'Edit Menu Item' : 'Add New Menu Item',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios, size: 18),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading categories...'),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.grey[100]!,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).custom.customLightGrey,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
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
                                  Icons.restaurant_menu,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.menuItem != null
                                          ? 'Edit Menu Item'
                                          : 'Add New Item',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fill in the details below to ${widget.menuItem != null ? 'update' : 'add'} your menu item',
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
                        const SizedBox(height: 32),

                        // Category Selection
                        _buildSectionTitle('Category', Icons.category),
                        const SizedBox(height: 12),

                        // Show message if no categories are available
                        if (_categories.isEmpty && !_isLoading)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No categories available. Please create a category first.',
                                    style: TextStyle(color: Colors.orange[800]),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_categories.isEmpty && !_isLoading)
                          const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedCategoryId,
                                    hint: Text(
                                      'Select a category',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                    isExpanded: true,
                                    icon: Icon(Icons.keyboard_arrow_down,
                                        color: Colors.grey[600]),
                                    items: _categories
                                        .where((category) =>
                                            category['id'] != null &&
                                            category['name'] != null)
                                        .map((category) {
                                      return DropdownMenuItem<int>(
                                        value: category['id'],
                                        child: Text(
                                          category['name'] ??
                                              'Unknown Category',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategoryId = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: IconButton(
                                onPressed: _refreshCategories,
                                icon: const Icon(Icons.refresh,
                                    color: Colors.blue),
                                tooltip: 'Refresh categories',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Basic Information Section
                        _buildSectionTitle(
                            'Basic Information', Icons.info_outline),
                        const SizedBox(height: 16),

                        // Name Field
                        _buildModernTextField(
                          controller: _nameController,
                          label: 'Item Name *',
                          icon: Icons.restaurant,
                          hint: 'e.g., Crispy Chilli Baby Corn',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an item name';
                            }
                            return null;
                          },
                        ),

                        // Description Field
                        _buildModernTextField(
                          controller: _descriptionController,
                          label: 'Description *',
                          icon: Icons.description,
                          hint: 'Describe the dish...',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),

                        // Price Field
                        _buildModernTextField(
                          controller: _priceController,
                          label: 'Price (₹) *',
                          icon: Icons.attach_money,
                          hint: 'e.g., 280.00',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),

                        // Image URL Field
                        _buildModernTextField(
                          controller: _imageUrlController,
                          label: 'Image URL',
                          icon: Icons.image,
                          hint: 'https://example.com/image.jpg',
                        ),

                        const SizedBox(height: 32),

                        // Availability Section
                        _buildSectionTitle('Availability', Icons.toggle_on),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).custom.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .custom
                                    .black
                                    .withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isAvailable
                                      ? Theme.of(context)
                                          .custom
                                          .successColor
                                          .withOpacity(0.1)
                                      : Theme.of(context)
                                          .custom
                                          .errorColor
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _isAvailable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isAvailable
                                      ? Theme.of(context).custom.successColor
                                      : Theme.of(context).custom.errorColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Available for Order',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .custom
                                            .customBlack,
                                      ),
                                    ),
                                    Text(
                                      _isAvailable
                                          ? 'Customers can order this item'
                                          : 'Item is currently unavailable',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Theme.of(context).custom.customGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isAvailable,
                                onChanged: (value) {
                                  setState(() {
                                    _isAvailable = value;
                                  });
                                },
                                thumbColor: WidgetStateProperty.resolveWith(
                                    (states) => Theme.of(context).custom.white),
                                trackColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.selected)
                                            ? Theme.of(context)
                                                .custom
                                                .successColor
                                                .withOpacity(0.5)
                                            : Theme.of(context)
                                                .custom
                                                .customLightGrey),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Dietary Options Section
                        _buildSectionTitle('Dietary Information', Icons.eco),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).custom.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .custom
                                    .black
                                    .withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Vegan Option
                              _buildDietaryOption(
                                title: 'Vegan',
                                subtitle: 'Suitable for vegans',
                                icon: Icons.eco,
                                color: Colors.lightGreen,
                                value: _isVegan,
                                onChanged: (value) {
                                  setState(() {
                                    _isVegan = value ?? false;
                                  });
                                },
                              ),
                              _buildDivider(),

                              // Gluten-Free Option
                              _buildDietaryOption(
                                title: 'Gluten-Free',
                                subtitle: 'Contains no gluten',
                                icon: Icons.grain,
                                color: Theme.of(context).custom.warningColor,
                                value: _isGlutenFree,
                                onChanged: (value) {
                                  setState(() {
                                    _isGlutenFree = value ?? false;
                                  });
                                },
                              ),
                              _buildDivider(),

                              // Contains Nuts Option
                              _buildDietaryOption(
                                title: 'Contains Nuts',
                                subtitle: 'May contain nuts or nut traces',
                                icon: Icons.warning,
                                color: Theme.of(context).custom.errorColor,
                                value: _containsNuts,
                                onChanged: (value) {
                                  setState(() {
                                    _containsNuts = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Save Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveMenuItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).custom.transparent,
                              foregroundColor: Theme.of(context).custom.white,
                              shadowColor: Theme.of(context).custom.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              Theme.of(context).custom.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.menuItem != null
                                            ? 'Updating...'
                                            : 'Adding...',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.menuItem != null
                                            ? Icons.update
                                            : Icons.add,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.menuItem != null
                                            ? 'Update Menu Item'
                                            : 'Add Menu Item',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
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
      );
    } catch (e) {
      // Fallback UI in case of any initialization errors
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Add Menu Item'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
