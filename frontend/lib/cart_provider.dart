// lib/cart_provider.dart
import 'package:flutter/material.dart';
import 'models.dart';

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
}
