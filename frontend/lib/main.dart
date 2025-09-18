/*// In lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'favorites_provider.dart'; // Import the new provider
import 'menu_screen.dart';
import 'about_page.dart';
import 'contact_page.dart';
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
import 'waiter_cart_provider.dart';
import 'theme.dart';
import 'homepage.dart';
import 'loginpage.dart';
import 'signuppage.dart';
import 'forget_password_page.dart';
import 'phone-login_page.dart';
import 'phone_signup-page.dart';
import 'order_history_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'takeaway_page.dart';
import 'dine_in_page.dart';
import 'booking_history_page.dart';
import 'menu_screen.dart';
import 'about_page.dart';
import 'contact_page.dart';
import 'admin_dashboard_page.dart';
import 'manager_dashboard_page.dart';
import 'employee_dashboard_page.dart';
import 'delivery_dashboard_page.dart';
import 'kitchen_dashboard_page.dart';
import 'waiter_dashboard_page.dart';
import 'ch/user_dashboard_page.dart';
import 'debug_user_role.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'services/payment_service.dart';
import 'explore_menu_page.dart';
import 'pages/explore/all_day_picks_page.dart';
import 'pages/explore/fitness_categories_page.dart';
import 'pages/explore/subscription_combo_page.dart';
import 'book_table_page.dart';
import 'order_from_table_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- USE YOUR OWN SUPABASE CREDENTIALS ---
  await Supabase.initialize(
    url: 'https://hjvxiamgvcmwjejsmvho.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MDk1OTcsImV4cCI6MjA2OTE4NTU5N30.x7qzN7zB2oHbRaMJaIm8sQDTDO16NrzLRnzXDzSJW-U',
  );

  // Initialize Razorpay
  PaymentService.initialize();

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
        ChangeNotifierProvider(create: (ctx) => WaiterCartProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        // FavoritesProvider now depends on AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (ctx) => FavoritesProvider(null),
          update: (ctx, authProvider, previousFavorites) =>
              FavoritesProvider(authProvider),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Restaurant App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            initialRoute: '/',
            routes: {
              // CHANGED: '/' now points to AuthWrapper which handles redirects
              '/': (context) => const HomePage(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignUpPage(),
              '/profile': (context) => const UserDashboardPage(),
              '/forget_password_page': (context) => const ForgotPasswordPage(),
              '/phone_login': (context) => const PhoneLoginPage(),
              '/phone_signup': (context) => const PhoneSignUpPage(),
              '/edit_profile': (context) => const EditProfilePage(),
              '/change_password': (context) => const ChangePasswordPage(),
              '/order_history': (context) => const OrderHistoryPage(),
              '/dine-in': (context) => const DineInPage(),
              '/takeaway': (context) => TakeawayPage(),
              '/booking-history': (context) => const BookingHistoryPage(),
              '/menu': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return MenuScreen(initialCategory: args?['initialCategory'] as String?);
              },
              '/about': (context) => AboutPage(),
              '/contact': (context) => const ContactPage(),
              '/explore-menu': (context) => const ExploreMenuPage(),
              '/admin_dashboard': (context) => const AdminDashboardPage(),
              '/manager_dashboard': (context) => const ManagerDashboardPage(),
              '/employee_dashboard': (context) => const EmployeeDashboardPage(),
              '/waiter_dashboard': (context) => const WaiterDashboardPage(),
              '/debug_user_role': (context) => const DebugUserRole(),
              '/delivery_dashboard': (context) => const DeliveryDashboardPage(),
              '/kitchen_dashboard': (context) => const KitchenDashboardPage(),
              '/cart': (context) => const CartScreen(),
              '/favorites': (context) => const FavoritesScreen(),
              // Explore section detail pages
              '/explore/special-diet': (context) => const AllDayPicksPage(),
              '/explore/fitness': (context) => const FitnessCategoriesPage(),
              '/explore/subscription-combo': (context) => const SubscriptionComboPage(),
              // Table booking and ordering pages
              '/reserve-table': (context) => const BookTablePage(),
              '/order-from-table': (context) => const OrderFromTablePage(),
            },
          );
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
