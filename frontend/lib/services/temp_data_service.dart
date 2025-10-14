import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TempDataService {
  static const String _reservationDataKey = 'pending_reservation_data';
  static const String _orderDataKey = 'pending_order_data';
  static const String _tableOrderDataKey = 'pending_table_order_data';

  // Save pending reservation data
  static Future<void> savePendingReservation({
    required int partySize,
    required DateTime selectedDate,
    required String selectedTimeSlot,
    required String specialOccasion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'partySize': partySize,
      'selectedDate': selectedDate.toIso8601String(),
      'selectedTimeSlot': selectedTimeSlot,
      'specialOccasion': specialOccasion,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_reservationDataKey, json.encode(data));
  }

  // Get pending reservation data
  static Future<Map<String, dynamic>?> getPendingReservation() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_reservationDataKey);
    if (dataString != null) {
      try {
        final data = json.decode(dataString) as Map<String, dynamic>;
        // Check if data is not too old (24 hours)
        final timestamp = DateTime.parse(data['timestamp']);
        if (DateTime.now().difference(timestamp).inHours < 24) {
          return data;
        } else {
          // Remove old data
          await clearPendingReservation();
        }
      } catch (e) {
        print('Error parsing reservation data: $e');
        await clearPendingReservation();
      }
    }
    return null;
  }

  // Clear pending reservation data
  static Future<void> clearPendingReservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reservationDataKey);
  }

  // Save pending order data
  static Future<void> savePendingOrder({
    required String orderType, // 'delivery', 'takeaway', 'dine_in'
    required Map<String, dynamic> orderData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'orderType': orderType,
      'orderData': orderData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_orderDataKey, json.encode(data));
  }

  // Get pending order data
  static Future<Map<String, dynamic>?> getPendingOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_orderDataKey);
    if (dataString != null) {
      try {
        final data = json.decode(dataString) as Map<String, dynamic>;
        // Check if data is not too old (2 hours)
        final timestamp = DateTime.parse(data['timestamp']);
        if (DateTime.now().difference(timestamp).inHours < 2) {
          return data;
        } else {
          // Remove old data
          await clearPendingOrder();
        }
      } catch (e) {
        print('Error parsing order data: $e');
        await clearPendingOrder();
      }
    }
    return null;
  }

  // Clear pending order data
  static Future<void> clearPendingOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderDataKey);
  }

  // Save pending table order data
  static Future<void> savePendingTableOrder({
    required String tableCode,
    required Map<String, dynamic> orderData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'tableCode': tableCode,
      'orderData': orderData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_tableOrderDataKey, json.encode(data));
  }

  // Get pending table order data
  static Future<Map<String, dynamic>?> getPendingTableOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_tableOrderDataKey);
    if (dataString != null) {
      try {
        final data = json.decode(dataString) as Map<String, dynamic>;
        // Check if data is not too old (1 hour)
        final timestamp = DateTime.parse(data['timestamp']);
        if (DateTime.now().difference(timestamp).inHours < 1) {
          return data;
        } else {
          // Remove old data
          await clearPendingTableOrder();
        }
      } catch (e) {
        print('Error parsing table order data: $e');
        await clearPendingTableOrder();
      }
    }
    return null;
  }

  // Clear pending table order data
  static Future<void> clearPendingTableOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tableOrderDataKey);
  }

  // Clear all pending data
  static Future<void> clearAllPendingData() async {
    await clearPendingReservation();
    await clearPendingOrder();
    await clearPendingTableOrder();
  }
}
