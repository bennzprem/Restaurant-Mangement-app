// lib/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_models.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AppUser? _user;
  AppUser? get user => _user;

  String? get accessToken {
    return _supabase.auth.currentSession?.accessToken;
  }

  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isManager => _user?.role == 'manager';
  bool get isEmployee => _user?.role == 'employee';
  bool get isWaiter => _user?.role == 'waiter';
  bool get isDelivery => _user?.role == 'delivery';
  bool get isKitchen => _user?.role == 'kitchen';

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null) {
        _fetchUserProfile(session.user);
      } else {
        _user = null;
        notifyListeners();
      }
    });

    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _fetchUserProfile(currentUser);
    }
  }

  Future<void> _fetchUserProfile(User authUser) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role, name, avatar_Url') // Fixed: use avatar_Url (capital U)
          .eq('id', authUser.id)
          .single();

      _user = AppUser(
        id: authUser.id,
        email: authUser.email!,
        role: response['role'] ?? 'user',
        name: response['name'] ?? '', // Correctly uses name
        avatarUrl: response['avatar_Url'], // Fixed: use avatar_Url (capital U)
      );
    } catch (e) {

      _user = null;
    }
    notifyListeners();
    // After updating, optionally navigate based on role can be handled by UI layer
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {

      // Force clear user state even if signOut fails
      _user = null;
      notifyListeners();
      rethrow;
    }
  }

  // vvv THIS IS THE MISSING FUNCTION vvv
  /// Re-fetches user data from the database to update the state.
  Future<void> refreshUserProfile() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      await _fetchUserProfile(currentUser);
    }
  }

  /// Manually refresh the authentication state
  Future<void> refreshAuthState() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      await _fetchUserProfile(currentUser);
    } else {
      _user = null;
      notifyListeners();
    }
  }
}
