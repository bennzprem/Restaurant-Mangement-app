/*// lib/favorites_provider.dart
import 'dart:collection';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final int _userId = 1; // Hardcoded user ID for demonstration
  String _error = '';
  String get error => _error;

  List<MenuItem> _favoriteItems = [];
  bool _isLoading = false;

  UnmodifiableListView<MenuItem> get favoriteItems =>
      UnmodifiableListView(_favoriteItems);
  bool get isLoading => _isLoading;

  // A quick lookup Set for checking if an item is a favorite by its ID
  Set<int> get _favoriteIds => _favoriteItems.map((item) => item.id).toSet();

  FavoritesProvider() {
    fetchFavorites();
  }

  bool isFavorite(int menuItemId) {
    return _favoriteIds.contains(menuItemId);
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    _error = ''; // Reset error on new fetch
    notifyListeners();

    try {
      _favoriteItems = await _apiService.fetchFavorites(_userId);
    } catch (e) {
      _error = "Failed to load favorites. Please try again.";

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFavorite(MenuItem item) async {
    if (isFavorite(item.id)) return;

    _favoriteItems.add(item);
    notifyListeners();
    await _apiService.addFavorite(_userId, item.id);
  }

  Future<void> removeFavorite(MenuItem item) async {
    if (!isFavorite(item.id)) return;

    _favoriteItems.removeWhere((menuItem) => menuItem.id == item.id);
    notifyListeners();
    await _apiService.removeFavorite(_userId, item.id);
  }

  // In class FavoritesProvider...

  Future<void> toggleFavorite(MenuItem item) async {
    final isCurrentlyFavorite = isFavorite(item.id);

    // Call the API first to make the change in the database
    try {
      if (isCurrentlyFavorite) {
        await _apiService.removeFavorite(_userId, item.id);
      } else {
        await _apiService.addFavorite(_userId, item.id);
      }
      // After the API call succeeds, fetch the updated list from the server
      await fetchFavorites();
    } catch (e) {

      // Optionally show an error to the user
    }
  }
}
*/
// lib/favorites_provider.dart
import 'dart:collection';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth_provider.dart'; // Import AuthProvider
import '../models/models.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthProvider? _authProvider; // Can now be null

  String? get _userId =>
      _authProvider?.user?.id; // Get user ID from AuthProvider

  List<MenuItem> _favoriteItems = [];
  bool _isLoading = false;
  String _error = '';

  FavoritesProvider(this._authProvider) {
    // Fetch favorites only if the user is logged in
    if (_authProvider?.isLoggedIn == true) {
      fetchFavorites();
    }
  }

  UnmodifiableListView<MenuItem> get favoriteItems =>
      UnmodifiableListView(_favoriteItems);
  bool get isLoading => _isLoading;
  String get error => _error;
  Set<int> get _favoriteIds => _favoriteItems.map((item) => item.id).toSet();

  bool isFavorite(int menuItemId) {
    return _favoriteIds.contains(menuItemId);
  }

  // In class FavoritesProvider...

  // In class FavoritesProvider...

  Future<void> fetchFavorites() async {
    if (_userId == null) return;
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      // FIXED: Pass the String user ID directly without parsing
      _favoriteItems = await _apiService.fetchFavorites(_userId!);
    } catch (e) {
      _error = "Failed to load favorites.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(MenuItem item) async {
    if (_userId == null) return;
    final isCurrentlyFavorite = isFavorite(item.id);
    try {
      if (isCurrentlyFavorite) {
        // FIXED: Pass the String user ID and int menu_item_id
        await _apiService.removeFavorite(_userId!, item.id);
      } else {
        await _apiService.addFavorite(_userId!, item.id);
      }
      await fetchFavorites();
    } catch (e) {

    }
  }
}
