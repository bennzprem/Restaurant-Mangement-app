/*// In lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart'; // Import the new provider
import 'menu_screen.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap with MultiProvider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(),
        ), // Add this
      ],
      child: MaterialApp(
        title: 'Restaurant',
        theme: AppTheme.theme,
        home: const MenuScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}*/
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart';
import 'homepage.dart';
import 'loginpage.dart';
import 'signuppage.dart';
import 'forget_password_page.dart';
import 'phone-login_page.dart';
import 'phone_signup-page.dart';
import 'my_profile_page.dart';
import 'order_history_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'takeaway_page.dart';
import 'book_table_page.dart';
import 'dine_in_page.dart';
import 'booking_history_page.dart';
import 'takeaway_page.dart';
import 'menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- USE YOUR OWN SUPABASE CREDENTIALS ---
  await Supabase.initialize(
    url: 'https://hjvxiamgvcmwjejsmvho.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MDk1OTcsImV4cCI6MjA2OTE4NTU5N30.x7qzN7zB2oHbRaMJaIm8sQDTDO16NrzLRnzXDzSJW-U',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        // FavoritesProvider now depends on AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (ctx) => FavoritesProvider(null),
          update: (ctx, authProvider, previousFavorites) =>
              FavoritesProvider(authProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Restaurant App',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          // CHANGED: '/' now points to AuthWrapper which handles redirects
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/profile': (context) => const MyProfilePage(),
          '/forget_password_page': (context) => const ForgotPasswordPage(),
          '/phone_login': (context) => const PhoneLoginPage(),
          '/phone_signup': (context) => const PhoneSignUpPage(),
          '/edit_profile': (context) => const EditProfilePage(),
          '/change_password': (context) => const ChangePasswordPage(),
          '/order_history': (context) => const OrderHistoryPage(),
          '/dine-in': (context) => const DineInPage(),
          '/takeaway': (context) => TakeawayPage(),
          '/booking-history': (context) => const BookingHistoryPage(),
          '/menu': (context) => const MenuScreen(),
        },
      ),
    );
  }
}
/*
// Add this class to the bottom of main.dart
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Supabase provides a stream to listen to auth changes
    final authStream = Supabase.instance.client.auth.onAuthStateChange;

    return StreamBuilder(
      stream: authStream,
      builder: (context, snapshot) {
        // If the user is logged in, show the HomePage
        if (Supabase.instance.client.auth.currentUser != null) {
          return const HomePage();
        }
        // Otherwise, show the LoginPage
        else {
          return const LoginPage();
        }
      },
    );
  }
}
*/
