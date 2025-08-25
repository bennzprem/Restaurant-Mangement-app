// lib/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart'; // or file_picker
import 'package:restaurant_app/models.dart' as app_models;
import 'package:http_parser/http_parser.dart';

import 'user_models.dart';

class ApiService {
  //final String baseUrl = "http://localhost:5000"; // For Web and Desktop
  final String baseUrl = kIsWeb
      ? "http://127.0.0.1:5000" // for web
      : "http://10.0.2.2:5000"; // for Android emulator
  // In lib/api_service.dart

  // Change this method
  // In class ApiService...

  Future<List<MenuCategory>> fetchMenu({
    required bool vegOnly,
    required bool veganOnly,
    required bool glutenFreeOnly,
    required bool nutsFree,
    String? searchQuery,
  }) async {
    final queryParameters = {
      'veg_only': vegOnly.toString(),
      'is_vegan': veganOnly.toString(),
      'is_gluten_free': glutenFreeOnly.toString(),
      'nuts_free': nutsFree.toString(),
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
    };

    // Remove filters that are 'false' to keep the URL clean
    queryParameters.removeWhere((key, value) => value == 'false');

    final uri = Uri.parse(
      '$baseUrl/menu',
    ).replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => MenuCategory.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load menu');
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

  Future<void> uploadProfilePicture(String userId, XFile imageFile) async {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) throw Exception('User not logged in');

    final uri = Uri.parse('$baseUrl/users/$userId/profile-picture');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $accessToken';

    // --- THIS IS THE KEY FIX ---
    // The key has been changed from 'profile_picture' to 'avatar'
    request.files.add(
      http.MultipartFile.fromBytes(
        'avatar', // <-- THE CORRECT KEY
        await imageFile.readAsBytes(),
        filename: imageFile.name,
        contentType: MediaType('image', imageFile.name.split('.').last),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print('Upload failed with response: ${response.body}');
      throw Exception('Failed to upload image');
    }
  }

  // Add this new method inside your ApiService class
  Future<List<app_models.Table>> fetchAvailableTables({
    required String date,
    required String time,
    required int partySize,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/available-tables?date=$date&time=$time&party_size=$partySize',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // The json.decode creates a List<dynamic>
      final List<dynamic> data = json.decode(response.body);

      // We map over the dynamic list, create a Table object for each item,
      // and then call .toList() to convert the result into a List<app_models.Table>
      return data.map((json) => app_models.Table.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch available tables: ${response.body}');
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
      return data.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
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

  final _supabase = Supabase.instance.client;

  Future<List<AppUser>> getAllUsers() async {
    // IMPORTANT: Make sure this is your permanent admin's user ID.
    const String permanentAdminId = 'db13418e-05f9-4101-9567-ecbfc938a325';

    try {
      final response = await _supabase
          .from('users')
          .select()
          .neq('id', permanentAdminId); // Exclude the permanent admin

      final users = (response as List)
          .map((userData) => AppUser.fromJson(userData))
          .toList();
      return users;
    } catch (e) {
      print('Error getting all users: $e');
      throw 'Failed to load users.';
    }
  }

  /// Updates the role for a specific user in the 'users' table.
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      print('Error updating user role: $e');
      throw 'Failed to update role.';
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
}
