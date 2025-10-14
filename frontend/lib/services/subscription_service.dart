// lib/services/subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../subscription_models.dart';

class SubscriptionService {
  static const String baseUrl = 'http://localhost:5000'; // Your backend URL

  // Headers for API requests
  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // SUBSCRIPTION PLANS
  // =====================================================

  /// Fetch all available subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription-plans'),
        headers: _getHeaders(null),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((plan) => SubscriptionPlan.fromJson(plan)).toList();
      } else {
        throw Exception(
            'Failed to load subscription plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription plans: $e');
    }
  }

  /// Fetch a specific subscription plan by ID
  Future<SubscriptionPlan> getSubscriptionPlan(int planId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription-plans/$planId'),
        headers: _getHeaders(null),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SubscriptionPlan.fromJson(data);
      } else {
        throw Exception(
            'Failed to load subscription plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription plan: $e');
    }
  }

  // =====================================================
  // USER SUBSCRIPTIONS
  // =====================================================

  /// Get user's current active subscription
  Future<UserSubscription?> getCurrentSubscription(
      String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/subscription'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserSubscription.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // No active subscription
      } else {
        throw Exception('Failed to load subscription: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription: $e');
    }
  }

  /// Get user's subscription history
  Future<List<UserSubscription>> getSubscriptionHistory(
      String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/subscriptions'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((sub) => UserSubscription.fromJson(sub)).toList();
      } else {
        throw Exception(
            'Failed to load subscription history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription history: $e');
    }
  }

  /// Create a new subscription
  Future<UserSubscription> createSubscription({
    required String userId,
    required int planId,
    required String token,
    required String paymentId,
    required String paymentOrderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions'),
        headers: _getHeaders(token),
        body: json.encode({
          'user_id': userId,
          'plan_id': planId,
          'payment_id': paymentId,
          'payment_order_id': paymentOrderId,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserSubscription.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to create subscription: ${errorData['error'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  /// Cancel a subscription
  Future<bool> cancelSubscription(int subscriptionId, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/cancel'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error cancelling subscription: $e');
    }
  }

  /// Pause a subscription
  Future<bool> pauseSubscription(int subscriptionId, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/pause'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error pausing subscription: $e');
    }
  }

  /// Resume a paused subscription
  Future<bool> resumeSubscription(int subscriptionId, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/resume'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error resuming subscription: $e');
    }
  }

  // =====================================================
  // CREDIT TRANSACTIONS
  // =====================================================

  /// Get user's credit transaction history
  Future<List<CreditTransaction>> getCreditHistory(
      int subscriptionId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/credits'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((transaction) => CreditTransaction.fromJson(transaction))
            .toList();
      } else {
        throw Exception(
            'Failed to load credit history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching credit history: $e');
    }
  }

  /// Use credits for an order
  Future<bool> useCredits({
    required int subscriptionId,
    required int orderId,
    required int creditsToUse,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/use-credits'),
        headers: _getHeaders(token),
        body: json.encode({
          'order_id': orderId,
          'credits_used': creditsToUse,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error using credits: $e');
    }
  }

  // =====================================================
  // SUBSCRIPTION PAYMENTS
  // =====================================================

  /// Get subscription payment history
  Future<List<SubscriptionPayment>> getPaymentHistory(
      int subscriptionId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/payments'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((payment) => SubscriptionPayment.fromJson(payment))
            .toList();
      } else {
        throw Exception(
            'Failed to load payment history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payment history: $e');
    }
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  /// Check if user has enough credits for an order
  Future<bool> hasEnoughCredits({
    required int subscriptionId,
    required double orderAmount,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/check-credits'),
        headers: _getHeaders(token),
        body: json.encode({
          'order_amount': orderAmount,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['has_enough_credits'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Calculate how many credits are needed for an order
  Future<int> calculateCreditsNeeded({
    required int subscriptionId,
    required double orderAmount,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/calculate-credits'),
        headers: _getHeaders(token),
        body: json.encode({
          'order_amount': orderAmount,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['credits_needed'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Get subscription analytics for user
  Future<Map<String, dynamic>> getSubscriptionAnalytics(
      String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/subscription-analytics'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load subscription analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription analytics: $e');
    }
  }
}
