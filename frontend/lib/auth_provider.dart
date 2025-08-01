// lib/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  bool get isLoggedIn => _user != null;

  String? get accessToken {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  AuthProvider() {
    // Get the initial user state
    _user = Supabase.instance.client.auth.currentUser;

    // Listen for future auth changes (login/logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // In class AuthProvider...
  Future<void> refreshUser() async {
    // This fetches the latest user data from Supabase, including metadata
    await Supabase.instance.client.auth.refreshSession();
    _user = Supabase.instance.client.auth.currentUser;
    notifyListeners();
  }
}
