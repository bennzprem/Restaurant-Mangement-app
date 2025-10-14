// lib/add_edit_menu_item_page_simple.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';

class AddEditMenuItemPageSimple extends StatefulWidget {
  final MenuItem? menuItem;
  final int? preSelectedCategoryId;
  final VoidCallback? onItemSaved;
  final VoidCallback? onCategoryUpdated;

  const AddEditMenuItemPageSimple({
    super.key,
    this.menuItem,
    this.preSelectedCategoryId,
    this.onItemSaved,
    this.onCategoryUpdated,
  });

  @override
  State<AddEditMenuItemPageSimple> createState() =>
      _AddEditMenuItemPageSimpleState();
}

class _AddEditMenuItemPageSimpleState extends State<AddEditMenuItemPageSimple> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isAvailable = true;
  bool _isVeg = true;
  bool _isBestseller = false;
  bool _isChefSpecial = false;
  bool _isSeasonal = false;

  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isSaving = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadCategories();
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
      _nameController.text = widget.menuItem!.name;
      _descriptionController.text = widget.menuItem!.description;
      _priceController.text = widget.menuItem!.price.toString();
      _imageUrlController.text = widget.menuItem!.imageUrl;
      _isAvailable = widget.menuItem!.isAvailable;
      _isVeg = widget.menuItem!.isVegan; // Map isVegan to isVeg
      _isBestseller = widget.menuItem!.isBestseller;
      _isChefSpecial = widget.menuItem!.isChefSpecial;
      _isSeasonal = widget.menuItem!.isSeasonal;
      _selectedCategoryId = widget.menuItem!.categoryId;
    } else if (widget.preSelectedCategoryId != null) {
      // Pre-select the category when adding a new item to a specific category
      _selectedCategoryId = widget.preSelectedCategoryId;
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _apiService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      if (_categories.isNotEmpty) {
        // Only set default category if no pre-selected category and no existing menu item
        if (_selectedCategoryId == null) {
          _selectedCategoryId = _categories.first['id'];
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _categories = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
            widget.menuItem != null ? 'Edit Menu Item' : 'Add New Menu Item'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty == true ? 'Price is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'],
                          child: Text(category['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isAvailable,
                          onChanged: (value) =>
                              setState(() => _isAvailable = value ?? true),
                        ),
                        const Text('Available'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isVeg,
                          onChanged: (value) =>
                              setState(() => _isVeg = value ?? true),
                        ),
                        const Text('Vegetarian'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isBestseller,
                          onChanged: (value) =>
                              setState(() => _isBestseller = value ?? false),
                        ),
                        const Text('Bestseller'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isChefSpecial,
                          onChanged: (value) =>
                              setState(() => _isChefSpecial = value ?? false),
                        ),
                        const Text('Chef Special'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isSeasonal,
                          onChanged: (value) =>
                              setState(() => _isSeasonal = value ?? false),
                        ),
                        const Text('Seasonal'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveMenuItem,
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(widget.menuItem != null
                              ? 'Update Item'
                              : 'Add Item'),
                    ),
                    const SizedBox(height: 32), // Extra padding at bottom
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final price = double.parse(_priceController.text);

      if (widget.menuItem != null) {
        await _apiService.updateMenuItem(
          id: widget.menuItem!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrl: _imageUrlController.text.trim(),
          isAvailable: _isAvailable,
          isVegan: _isVeg, // Use the correct field
          isGlutenFree: false, // Not used in database
          containsNuts: false, // Not used in database
          categoryId: _selectedCategoryId!,
          isBestseller: _isBestseller,
          isChefSpecial: _isChefSpecial,
          isSeasonal: _isSeasonal,
        );
      } else {
        await _apiService.createMenuItem(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrl: _imageUrlController.text.trim(),
          isAvailable: _isAvailable,
          isVegan: _isVeg, // Use the correct field
          isGlutenFree: false, // Not used in database
          containsNuts: false, // Not used in database
          categoryId: _selectedCategoryId!,
          isBestseller: _isBestseller,
          isChefSpecial: _isChefSpecial,
          isSeasonal: _isSeasonal,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.menuItem != null
              ? 'Menu item updated successfully!'
              : 'Menu item added successfully!'),
        ),
      );

      widget.onItemSaved?.call();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
