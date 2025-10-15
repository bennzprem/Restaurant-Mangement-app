// lib/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // or file_picker
// Removed incorrect package import; using local models.dart

import '../models/user_models.dart';

class ApiService {
  final String baseUrl = kIsWeb
      ? "http://localhost:5000" // for web
      : "http://10.0.2.2:5000"; // for Android emulator
  // In lib/api_service.dart

  // Change this method
  // In class ApiService...

  Future<List<String>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories')).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - backend server may not be running');
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body
            .map((dynamic item) => item['name'] as String)
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Failed to fetch') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to backend server. Please ensure the backend is running on $baseUrl');
      }
      rethrow;
    }
  }

  Future<List<MenuCategory>> fetchMenu({
    required bool vegOnly,
    required bool veganOnly,
    required bool glutenFreeOnly,
    required bool nutsFree,
    bool? isBestseller,
    bool? isChefSpl,
    bool? isSeasonal,
    String? searchQuery,
    String? mealTime, // breakfast | lunch | snacks | dinner
    bool? isHighProtein,
    bool? isLowCarb,
    bool? isBalanced,
    bool? isBulkUp,
    String? subscriptionType, // weekly, monthly, family_pack, office_lunch
  }) async {
    final queryParameters = {
      'veg_only': vegOnly.toString(),
      'is_vegan': veganOnly.toString(),
      'is_gluten_free': glutenFreeOnly.toString(),
      'nuts_free': nutsFree.toString(),
      if (isBestseller != null) 'is_bestseller': isBestseller.toString(),
      if (isChefSpl != null) 'is_chef_spl': isChefSpl.toString(),
      if (isSeasonal != null) 'is_seasonal': isSeasonal.toString(),
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      if (mealTime != null && mealTime.isNotEmpty) 'meal_time': mealTime,
      if (isHighProtein != null) 'is_high_protein': isHighProtein.toString(),
      if (isLowCarb != null) 'is_low_carb': isLowCarb.toString(),
      if (isBalanced != null) 'is_balanced': isBalanced.toString(),
      if (isBulkUp != null) 'is_bulk_up': isBulkUp.toString(),
      if (subscriptionType != null && subscriptionType.isNotEmpty)
        'subscription_type': subscriptionType,
    };

    // Remove old filter parameters that are 'false' to keep the URL clean
    // But keep the new boolean filter parameters even if they're false
    queryParameters.removeWhere((key, value) =>
        value == 'false' &&
        ![
          'is_bestseller',
          'is_chef_spl',
          'is_seasonal',
          'is_high_protein',
          'is_low_carb',
          'is_balanced',
          'is_bulk_up'
        ].contains(key));

    final uri = Uri.parse(
      '$baseUrl/menu',
    ).replace(queryParameters: queryParameters);
    
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - backend server may not be running');
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => MenuCategory.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load menu: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Failed to fetch') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to backend server. Please ensure the backend is running on $baseUrl');
      }
      rethrow;
    }
  }

  // In class ApiService...

  Future<Map<String, dynamic>> placeOrder(
    List<CartItem> items,
    double total,
    String userId,
    String address,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'total': total,
        'user_id': userId,
        'address': address,
        'items': items
            .map(
              (item) => {
                // --- THIS IS THE FIX ---
                // Use the exact column names from your Supabase table
                'menu_item_id': item.menuItem.id,
                'quantity': item.quantity,
                'price_at_order': item.menuItem.price,
              },
            )
            .toList(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to place order');
    }
  }

  Future<String> fetchOrderStatus(int orderId) async {
    final response = await http.get(Uri.parse('$baseUrl/order/$orderId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['status'];
    } else {
      throw Exception('Failed to track order');
    }
  }

  Future<Map<String, dynamic>> fetchOrderDetails(int orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$orderId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fetch order details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  Future<List<MenuItem>> fetchFavorites(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/favorites'),
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => MenuItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  Future<void> addFavorite(String userId, int menuItemId) async {
    await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'menu_item_id': menuItemId}),
    );
  }

  Future<void> removeFavorite(String userId, int menuItemId) async {
    await http.delete(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'menu_item_id': menuItemId}),
    );
  }

  // In class ApiService...
  // NOTE: For this to work cleanly, your ApiService might need access to the AuthProvider.
  // A simple way is to pass the userId to the function. We'll update the call in the page.

  Future<List<Order>> fetchOrderHistory(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/orders'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load order history');
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Order.fromJson(e)).toList();
      }
      throw 'Failed to load orders: ${response.statusCode}';
    } catch (e) {
      throw 'Failed to load orders.';
    }
  }

  Future<int> getOrdersCountAccurate() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/count'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Order management methods
  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders/$orderId/items'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw 'Failed to load order items: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to load order items.';
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode != 200) {
        throw 'Failed to update order status: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to update order status.';
    }
  }

  Future<List<MenuItem>> getAllMenuItems() async {
    try {
      // Use the existing fetchMenu method that we know works
      final menuCategories = await fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
      );

      List<MenuItem> allMenuItems = [];
      for (var category in menuCategories) {
        allMenuItems.addAll(category.items);
      }

      return allMenuItems;
    } catch (e) {
      throw 'Failed to load menu items.';
    }
  }

  Future<List<MenuItem>> getRecommendations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recommendations/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recommendations = data['recommendations'] ?? [];

        return recommendations.map((item) => MenuItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      // Fallback to bestseller items if recommendation fails
      final allMenuItems = await getAllMenuItems();
      final bestsellers = allMenuItems
          .where((item) => item.isBestseller == true)
          .take(3)
          .toList();
      return bestsellers;
    }
  }

  // AI-powered craving search using Groq LLM + Pinecone
  Future<List<MenuItem>> findCraving(String craving) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/find_craving'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'craving': craving}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> matches = data['matches'] ?? [];

        // Convert the matches to MenuItem objects
        return matches.map((match) {
          // Create a MenuItem from the match data
          return MenuItem(
            id: match['id'],
            name: match['name'],
            description: match['description'],
            price: (match['metadata']?['price'] ?? 0.0).toDouble(),
            imageUrl: match['metadata']?['image_url'] ?? '',
            isVegetarian: match['metadata']?['is_veg'] ?? false,
            isBestseller: match['metadata']?['is_bestseller'] ?? false,
            isAvailable: match['metadata']?['is_available'] ?? true,
            categoryId: match['metadata']?['category_id'] ?? 1,
            isVegan: false, // Not available in search results
            isGlutenFree: false, // Not available in search results
            containsNuts: false, // Not available in search results
          );
        }).toList();
      } else {
        throw Exception('Failed to search craving: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search craving: $e');
    }
  }

  // In class ApiService...
  // In lib/api_service.dart...
  // In class ApiService...

  Future<void> updateProfile(String userId, String name) async {
    // Get the current user's token to authorize the request
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) throw Exception('User not logged in');

    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        // THIS IS THE FIX: Send the token in the headers
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  // In class ApiService...
  Future<void> changePassword(String newPassword) async {
    // Get the current user's JWT to securely identify them on the backend
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) throw Exception('User not logged in');

    final response = await http.post(
      Uri.parse('$baseUrl/users/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'new_password': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change password');
    }
  }

  Future<String?> uploadProfilePicture(String userId, XFile imageFile) async {
    try {
      final fileExt = imageFile.name.split('.').last;
      final fileName = '$userId.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload to Supabase storage bucket
      await Supabase.instance.client.storage
          .from('profile-pictures')
          .uploadBinary(
            filePath,
            await imageFile.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('profile-pictures')
          .getPublicUrl(filePath);

      // Save publicUrl to the `users` table (so you can fetch it later)
      await Supabase.instance.client
          .from('users')
          .update({'avatar_Url': publicUrl}).eq('id', userId);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfileInfo(
      String userId, Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to update profile info');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add this new method inside your ApiService class
  Future<List<Table>> fetchAvailableTables({
    required String date,
    required String time,
    required int partySize,
  }) async {
    final url =
        '$baseUrl/api/available-tables?date=$date&time=$time&party_size=$partySize';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // The json.decode creates a List<dynamic>
        final List<dynamic> data = json.decode(response.body);

        // We map over the dynamic list, create a Table object for each item,
        // and then call .toList() to convert the result into a List<app_models.Table>
        final tables = data.map((json) => Table.fromJson(json)).toList();
        return tables;
      } else {
        throw Exception(
            'Failed to fetch available tables: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add this method as well for creating the reservation
  Future<void> createReservation({
    required String tableId,
    required String reservationTime,
    required int partySize,
    required String specialOccasion,
    required String authToken, // The user's JWT
    required bool addOnsRequested,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reservations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken', // Send the token for auth
      },
      body: json.encode({
        'table_id': tableId,
        'reservation_time': reservationTime,
        'party_size': partySize,
        'special_occasion': specialOccasion,
        'add_ons_requested': addOnsRequested,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create reservation: ${response.body}');
    }
  }
  // In lib/api_service.dart

  // Method to fetch all reservations for the logged-in user
  Future<List<Reservation>> getReservations(String authToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reservations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) {
        try {
          return Reservation.fromJson(json);
        } catch (e) {
          // Return a default reservation to prevent the entire list from failing
          return Reservation(
            id: json['id'] ?? 'unknown',
            reservationTime: DateTime.now(),
            partySize: json['party_size'] ?? 2,
            status: json['status'] ?? 'pending',
            specialOccasion: json['special_occasion'] ?? 'None',
            addOnsRequested: json['add_ons_requested'] ?? false,
            table: Table(
              id: json['table_id'] ?? 'unknown',
              tableNumber: json['table_number'] ?? 1,
              capacity: json['table_capacity'] ?? 4,
              locationPreference: json['location_preference'],
            ),
          );
        }
      }).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  // Method to check table availability
  Future<Map<String, dynamic>> checkTableAvailability({
    required String date,
    required String time,
    required int partySize,
    required String authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tables/availability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'date': date,
          'time': time,
          'party_size': partySize,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to check table availability: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking table availability: $e');
    }
  }

  // Method to check if user has existing booking at the same time
  Future<bool> hasExistingBooking({
    required String date,
    required String time,
    required String authToken,
  }) async {
    try {
      final reservations = await getReservations(authToken);

      // Check if any reservation matches the same date and time
      final hasConflict = reservations.any((reservation) {
        try {
          final reservationDate =
              DateFormat('yyyy-MM-dd').format(reservation.reservationTime);
          final reservationTime =
              DateFormat('HH:mm').format(reservation.reservationTime);

          return reservationDate == date && reservationTime == time;
        } catch (e) {
          return false; // Skip this reservation if there's an error
        }
      });

      return hasConflict;
    } catch (e) {
      // If we can't check, assume no conflict to avoid blocking legitimate bookings
      return false;
    }
  }

  // Method to cancel a specific reservation
  Future<void> cancelReservation({
    required String reservationId,
    required String authToken,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/reservations/$reservationId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel reservation');
    }
  }
  // In lib/api_service.dart

// This function will call the backend to validate the table code
  Future<Map<String, dynamic>> startTableSession(String tableCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/table-sessions/start'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'session_code': tableCode}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Try to parse a specific error message from the backend
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to start table session.');
    }
  }

  // Simple table count method
  Future<Map<String, dynamic>> getTablesCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tables/count'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw 'Failed to load table count: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to load table count.';
    }
  }

  // Close all active table sessions (admin/testing utility)
  Future<int> closeAllTableSessions() async {
    final response =
        await http.post(Uri.parse('$baseUrl/api/table-sessions/close-all'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['closed'] ?? 0) as int;
    }
    throw Exception('Failed to close sessions: ${response.body}');
  }

  // Close a specific table session by ID
  Future<void> closeTableSession(String sessionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/table-sessions/close'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'session_id': sessionId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to close session: ${response.body}');
    }
  }

  // Fetch all tables with occupancy info
  Future<List<Map<String, dynamic>>> getTables() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tables'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load tables: ${response.body}');
  }

  // Toggle occupancy for a table
  Future<Map<String, dynamic>> toggleTable(dynamic tableId,
      {String? sessionCode}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tables/$tableId/toggle'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        if (sessionCode != null && sessionCode.isNotEmpty)
          'session_code': sessionCode,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to toggle table: ${response.body}');
  }

  // Create a new table (optionally with a session code)
  Future<Map<String, dynamic>> createTable({
    required int tableNumber,
    int capacity = 4,
    String? locationPreference,
    String? sessionCode,
  }) async {
    final payload = <String, dynamic>{
      'table_number': tableNumber,
      'capacity': capacity,
    };
    if (locationPreference != null && locationPreference.isNotEmpty) {
      payload['location_preference'] = locationPreference;
    }
    if (sessionCode != null && sessionCode.isNotEmpty) {
      payload['session_code'] = sessionCode.toUpperCase();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/tables'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final body = json.decode(response.body);
    throw Exception(body['error'] ?? 'Failed to create table');
  }

  // Claim a table session for a waiter by session code
  Future<Map<String, dynamic>> claimTableSession({
    required String sessionCode,
    required String waiterId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/table-sessions/claim');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'session_code': sessionCode,
        'waiter_id': waiterId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to claim table: ${response.body}');
  }

  // Submit items for a given table session; returns created orderId
  Future<int> addItemsToOrder({
    required String sessionId,
    required List<Map<String, dynamic>> items,
    String? waiterId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/add-items'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'session_id': sessionId,
        'items': items,
        'waiter_id': waiterId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Add items failed: ${response.body}');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['order_id'] as num).toInt();
  }

  // Get kitchen orders with waiter and food details
  Future<List<Map<String, dynamic>>> getKitchenOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/kitchen/orders'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load kitchen orders: ${response.body}');
    }
  }

  final _supabase = Supabase.instance.client;

  Future<List<AppUser>> getAllUsers() async {
    try {
      // Get ALL users from the database without any exclusions
      // Try different approaches to bypass RLS policies

      // Method 1: Basic select
      var response = await _supabase.from('users').select('*');

      // Method 2: If first method returns only 1 user, try with different approach
      if (response.length <= 1) {
        try {
          // Try to get users with explicit ordering
          response = await _supabase
              .from('users')
              .select('*')
              .order('created_at', ascending: false);
        } catch (e) {}
      }

      // Method 3: If still only 1 user, try selecting specific columns
      if (response.length <= 1) {
        try {
          response = await _supabase
              .from('users')
              .select('id, name, email, role, created_at');
        } catch (e) {}
      }

      // Print first few items for debugging
      for (int i = 0; i < response.length && i < 3; i++) {}

      final users = (response as List)
          .map((userData) {
            try {
              // Check if required fields exist
              if (userData['id'] == null) {
                return null;
              }

              if (userData['name'] == null) {
                return null;
              }

              if (userData['role'] == null) {
                userData['role'] = 'user';
              }

              final user =
                  AppUser.fromJson(Map<String, dynamic>.from(userData));
              return user;
            } catch (parseError) {
              // Try to create a minimal user object
              try {
                final minimalUser = AppUser(
                  id: userData['id']?.toString() ?? 'unknown',
                  email: userData['email']?.toString(),
                  name: userData['name']?.toString() ?? 'Unknown User',
                  role: userData['role']?.toString() ?? 'user',
                  avatarUrl: userData['avatar_Url']?.toString() ??
                      userData['avatar_url']?.toString(),
                );
                return minimalUser;
              } catch (minimalError) {
                return null;
              }
            }
          })
          .where((user) => user != null)
          .cast<AppUser>()
          .toList();

      // Check for any users without roles
      final usersWithoutRole =
          users.where((u) => u.role.isEmpty || u.role == 'null').toList();
      if (usersWithoutRole.isNotEmpty) {
        for (final user in usersWithoutRole) {}
      }

      // If we only got 1 user but should have 6, this indicates an RLS issue
      if (users.length == 1) {
        // RLS policies may be blocking access
      }

      return users;
    } catch (e) {
      throw 'Failed to load users: $e';
    }
  }

  /// Debug method to check database structure
  Future<void> debugDatabase() async {
    try {
      // Check users table with different approaches
      final usersResponse = await _supabase.from('users').select('*');

      final usersResponse2 =
          await _supabase.from('users').select('id, name, email, role');

      final countResponse = await _supabase.from('users').select('id');

      try {
        // Try to get all users with explicit service role
        final allUsers = await _supabase
            .from('users')
            .select('*')
            .order('created_at', ascending: false);

        if (allUsers.isNotEmpty) {}
      } catch (e) {}

      if (usersResponse.isNotEmpty) {
        // Check specific column names
        final firstUser = usersResponse.first as Map;
      }

      // Check if there are any users without roles
      final usersWithoutRole = usersResponse
          .where((u) =>
              u['role'] == null || u['role'] == '' || u['role'] == 'null')
          .toList();

      if (usersWithoutRole.isNotEmpty) {
        for (final user in usersWithoutRole) {
          // Users without roles found
        }
      }
    } catch (e) {
      // Error handling
    }
  }

  /// Creates a test user for demonstration purposes
  Future<void> createTestUser({
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      final response = await _supabase.from('users').insert({
        'name': name,
        'email': email,
        'role': role,
      }).select();
    } catch (e) {
      throw 'Failed to create test user: $e';
    }
  }

  /// Updates the role for a specific user in the 'users' table.
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      throw 'Failed to update role.';
    }
  }

  /// Fixes users without roles by setting them to 'user' role
  Future<void> fixUsersWithoutRoles() async {
    try {
      // Find users without roles
      final usersWithoutRole = await _supabase
          .from('users')
          .select('id, name, role')
          .or('role.is.null,role.eq.,role.eq.null');

      for (final user in usersWithoutRole) {
        if (user['role'] == null ||
            user['role'] == '' ||
            user['role'] == 'null') {
          await _supabase
              .from('users')
              .update({'role': 'user'}).eq('id', user['id']);
        }
      }
    } catch (e) {
      throw 'Failed to fix users without roles: $e';
    }
  }

  Future<String> createRazorpayOrder(double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-razorpay-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['order_id'];
    } else {
      throw Exception('Failed to create Razorpay order.');
    }
  }

  // Menu item management methods
  Future<void> createMenuItem({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required bool isAvailable,
    required bool isVegan,
    required bool isGlutenFree,
    required bool containsNuts,
    required int categoryId,
    bool isBestseller = false,
    bool isChefSpecial = false,
    bool isSeasonal = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/menu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'image_url': imageUrl,
          'is_available': isAvailable,
          'is_veg': isVegan, // Map isVegan to is_veg
          'is_bestseller': isBestseller,
          'is_chef_spl': isChefSpecial,
          'is_seasonal': isSeasonal,
          'category_id': categoryId,
        }),
      );

      if (response.statusCode == 201) {
      } else {
        throw 'Failed to create menu item: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to create menu item.';
    }
  }

  Future<void> updateMenuItem({
    required int id,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required bool isAvailable,
    required bool isVegan,
    required bool isGlutenFree,
    required bool containsNuts,
    required int categoryId,
    bool isBestseller = false,
    bool isChefSpecial = false,
    bool isSeasonal = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/menu/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'image_url': imageUrl,
          'is_available': isAvailable,
          'is_veg': isVegan, // Map isVegan to is_veg
          'is_bestseller': isBestseller,
          'is_chef_spl': isChefSpecial,
          'is_seasonal': isSeasonal,
          'category_id': categoryId,
        }),
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 404) {
        throw 'Menu item not found';
      } else {
        throw 'Failed to update menu item: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to update menu item.';
    }
  }

  Future<void> updateMenuItemAvailability(int id, bool isAvailable) async {
    try {
      // Use the Flask backend to update availability
      final response = await http.patch(
        Uri.parse('$baseUrl/menu/$id/availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_available': isAvailable}),
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 404) {
        throw 'Menu item not found';
      } else {
        throw 'Failed to update availability: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to update item availability: $e';
    }
  }

  Future<void> deleteMenuItem(int id) async {
    try {
      // Use the Flask backend to delete the menu item
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 404) {
        throw 'Menu item not found';
      } else {
        throw 'Failed to delete menu item: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to delete menu item: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final categories = data.cast<Map<String, dynamic>>();
        return categories;
      } else {
        throw 'Failed to load categories: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Failed to load categories: $e';
    }
  }

  // Category management methods
  Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['category'];
      } else {
        final errorData = json.decode(response.body);
        throw errorData['error'] ?? 'Failed to create category';
      }
    } catch (e) {
      throw 'Failed to create category: $e';
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw errorData['error'] ?? 'Failed to delete category';
      }
    } catch (e) {
      throw 'Failed to delete category: $e';
    }
  }

  // Kitchen dashboard methods (duplicate removed)

  // Table management methods (duplicates removed; using the API-prefixed implementations above)

  // Address management methods
  Future<List<SavedAddress>> getSavedAddresses(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/addresses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SavedAddress.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load saved addresses');
      }
    } catch (e) {
      throw Exception('Failed to load saved addresses: $e');
    }
  }

  Future<SavedAddress> saveAddress(SavedAddress address) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/${address.userId}/addresses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(address.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SavedAddress.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw errorData['error'] ?? 'Failed to save address';
      }
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  Future<void> updateAddress(SavedAddress address) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${address.userId}/addresses/${address.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(address.toJson()),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw errorData['error'] ?? 'Failed to update address';
      }
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw errorData['error'] ?? 'Failed to delete address';
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId/set-default'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw errorData['error'] ?? 'Failed to set default address';
      }
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  Future<SavedAddress?> getDefaultAddress(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/addresses/default'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data != null ? SavedAddress.fromJson(data) : null;
      } else if (response.statusCode == 404) {
        return null; // No default address found
      } else {
        throw Exception('Failed to load default address');
      }
    } catch (e) {
      return null; // Return null on error to allow fallback
    }
  }

  // Create a simple reservation in the database
  Future<Map<String, dynamic>> createSimpleReservation({
    required String tableNumber,
    required String date,
    required String time,
    required int partySize,
    required String specialOccasion,
    required String authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reservations/simple'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'table_number': tableNumber,
          'date': date,
          'time': time,
          'party_size': partySize,
          'special_occasion': specialOccasion,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to create reservation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating simple reservation: $e');
    }
  }

  // Complete a reservation when customer finishes dining
  Future<Map<String, dynamic>> completeReservation({
    required String reservationId,
    required String authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reservations/$reservationId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to complete reservation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error completing reservation: $e');
    }
  }
}
