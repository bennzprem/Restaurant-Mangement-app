import 'package:flutter/material.dart';
import 'models.dart';

class WaiterCartProvider with ChangeNotifier {
  // sessionId -> (menuItemId -> CartItem)
  final Map<String, Map<int, CartItem>> _sessionIdToItems = {};

  Map<int, CartItem> _ensureCart(String sessionId) {
    return _sessionIdToItems.putIfAbsent(sessionId, () => <int, CartItem>{});
  }

  Map<int, CartItem> items(String sessionId) => {..._ensureCart(sessionId)};

  // Public list of sessions that currently have items
  List<String> get activeSessionIds {
    return _sessionIdToItems.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  int getItemQuantity(String sessionId, int menuItemId) {
    final cart = _ensureCart(sessionId);
    return cart.containsKey(menuItemId) ? cart[menuItemId]!.quantity : 0;
  }

  double totalAmount(String sessionId) {
    final cart = _ensureCart(sessionId);
    var total = 0.0;
    cart.forEach((_, cartItem) {
      total += cartItem.menuItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(String sessionId, MenuItem menuItem) {
    final cart = _ensureCart(sessionId);
    if (cart.containsKey(menuItem.id)) {
      cart.update(
        menuItem.id,
        (existing) => CartItem(
          menuItem: existing.menuItem,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      cart[menuItem.id] = CartItem(menuItem: menuItem);
    }
    notifyListeners();
  }

  void removeSingleItem(String sessionId, int menuItemId) {
    final cart = _ensureCart(sessionId);
    if (!cart.containsKey(menuItemId)) return;
    final existing = cart[menuItemId]!;
    if (existing.quantity > 1) {
      cart[menuItemId] = CartItem(
          menuItem: existing.menuItem, quantity: existing.quantity - 1);
    } else {
      cart.remove(menuItemId);
    }
    notifyListeners();
  }

  void clearCart(String sessionId) {
    _ensureCart(sessionId).clear();
    notifyListeners();
  }
}
