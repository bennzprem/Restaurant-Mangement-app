// lib/cart_provider.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  // ADD THIS NEW METHOD
  int getItemQuantity(int menuItemId) {
    return _items.containsKey(menuItemId) ? _items[menuItemId]!.quantity : 0;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.menuItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items.update(
        menuItem.id,
        (existingCartItem) => CartItem(
          menuItem: existingCartItem.menuItem,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(menuItem.id, () => CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeSingleItem(int menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    if (_items[menuItemId]!.quantity > 1) {
      _items.update(
        menuItemId,
        (existing) => CartItem(
          menuItem: existing.menuItem,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(menuItemId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
void updateCartFromVoice(List<dynamic> voiceCartData) {
    // This method rebuilds the entire cart based on the new data from the backend.
    
    // Clear the existing cart to start fresh
    _items.clear();

    // Loop through the data from the backend and populate the cart map
    for (var itemData in voiceCartData) {
      // This parsing assumes your JSON structure from Supabase.
      // 'menu_items' is the name of the joined table.
      if (itemData['menu_items'] != null) {
        final menuItem = MenuItem.fromJson(itemData['menu_items']);
        final cartItem = CartItem(
          menuItem: menuItem,
          quantity: itemData['quantity'],
        );
        // Use the menu item's ID as the key in the map
        _items[menuItem.id] = cartItem;
      }
    }

    // This is the most important step: it tells the app to redraw the cart UI.

    notifyListeners();
  }
  }

