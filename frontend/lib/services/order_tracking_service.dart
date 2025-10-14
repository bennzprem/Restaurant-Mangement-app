import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class OrderTrackingService extends ChangeNotifier {
  static final OrderTrackingService _instance =
      OrderTrackingService._internal();
  factory OrderTrackingService() => _instance;
  OrderTrackingService._internal() {
    // Load orders immediately when service is created
    _loadActiveOrdersSync();
  }

  final List<ActiveOrder> _activeOrders = [];
  RealtimeChannel? _ordersChannel;
  Timer? _pollingTimer;

  List<ActiveOrder> get activeOrders {
    return List.unmodifiable(_activeOrders);
  }

  int get activeOrderCount {
    return _activeOrders.length;
  }

  bool get hasActiveOrders {
    return _activeOrders.isNotEmpty;
  }

  /// Start tracking orders for a user
  Future<void> startTracking(String userId) async {
    await _loadActiveOrders(); // Load from storage first

    await _fetchActiveOrders(userId); // Then fetch from server

    _startRealtimeSubscription(userId);
    _startPollingFallback(userId);
  }

  /// Stop tracking orders
  void stopTracking() {
    _ordersChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _activeOrders.clear();
    notifyListeners();
  }

  /// Add a new order to tracking
  void addOrder(ActiveOrder order) {
    final existingIndex = _activeOrders.indexWhere((o) => o.id == order.id);
    if (existingIndex >= 0) {
      _activeOrders[existingIndex] = order;
    } else {
      _activeOrders.add(order);
    }

    _saveActiveOrders();
    notifyListeners();
  }

  /// Remove an order from tracking
  void removeOrder(int orderId) {
    _activeOrders.removeWhere((order) => order.id == orderId);
    _saveActiveOrders(); // Save to storage
    notifyListeners();
  }

  /// Update order status
  void updateOrderStatus(int orderId, String status) {
    final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex >= 0) {
      _activeOrders[orderIndex] =
          _activeOrders[orderIndex].copyWith(status: status);
      _saveActiveOrders(); // Save to storage
      notifyListeners();
    }
  }

  Future<void> _fetchActiveOrders(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select(
              'id, status, total_amount, delivery_address, created_at, customer_name')
          .eq('user_id', userId)
          .or('status.eq.Preparing,status.eq.Ready for pickup,status.eq.Out for delivery')
          .order('created_at', ascending: false);

      _activeOrders.clear();
      for (final orderData in response) {
        _activeOrders.add(ActiveOrder.fromJson(orderData));
      }

      await _saveActiveOrders(); // Save to storage
      notifyListeners();
    } catch (e) {}
  }

  void _startRealtimeSubscription(String userId) {
    try {
      final supabase = Supabase.instance.client;
      _ordersChannel = supabase
          .channel('user-orders-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              final data = payload.newRecord as Map<String, dynamic>?;
              if (data != null) {
                final orderId = data['id'] as int?;
                final status = data['status'] as String?;

                if (orderId != null && status != null) {
                  if (['Preparing', 'Ready for pickup', 'Out for delivery']
                      .contains(status)) {
                    updateOrderStatus(orderId, status);
                  } else if (status == 'Delivered') {
                    removeOrder(orderId);
                  }
                }
              }
            },
          )
          .subscribe();
    } catch (e) {}
  }

  void _startPollingFallback(String userId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchActiveOrders(userId);
    });
  }

  /// Save active orders to SharedPreferences
  Future<void> _saveActiveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = _activeOrders.map((order) => order.toJson()).toList();
      await prefs.setString('active_orders', jsonEncode(ordersJson));
    } catch (e) {}
  }

  /// Load active orders from SharedPreferences (synchronous version)
  void _loadActiveOrdersSync() {
    try {
      // Use a synchronous approach for immediate loading
      SharedPreferences.getInstance().then((prefs) {
        final ordersString = prefs.getString('active_orders');
        if (ordersString != null) {
          final ordersList = jsonDecode(ordersString) as List;
          _activeOrders.clear();
          _activeOrders.addAll(
              ordersList.map((json) => ActiveOrder.fromJson(json)).toList());
          notifyListeners();
        }
      }).catchError((e) {
        // Error handling
      });
    } catch (e) {
      // Error handling
    }
  }

  /// Load active orders from SharedPreferences
  Future<void> _loadActiveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersString = prefs.getString('active_orders');

      if (ordersString != null) {
        final ordersList = jsonDecode(ordersString) as List;

        _activeOrders.clear();
        _activeOrders.addAll(
            ordersList.map((json) => ActiveOrder.fromJson(json)).toList());

        notifyListeners();
      } else {}
    } catch (e) {}
  }

  /// Clear all stored orders
  Future<void> clearStoredOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_orders');
      _activeOrders.clear();
      notifyListeners();
    } catch (e) {}
  }
}

class ActiveOrder {
  final int id;
  final String status;
  final double totalAmount;
  final String deliveryAddress;
  final DateTime createdAt;
  final String? customerName;

  ActiveOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.createdAt,
    this.customerName,
  });

  factory ActiveOrder.fromJson(Map<String, dynamic> json) {
    return ActiveOrder(
      id: json['id'],
      status: json['status'] ?? 'Preparing',
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customer_name'],
    );
  }

  ActiveOrder copyWith({
    int? id,
    String? status,
    double? totalAmount,
    String? deliveryAddress,
    DateTime? createdAt,
    String? customerName,
  }) {
    return ActiveOrder(
      id: id ?? this.id,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
    );
  }

  bool get isActive =>
      ['Preparing', 'Ready for pickup', 'Out for delivery'].contains(status);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'created_at': createdAt.toIso8601String(),
      'customer_name': customerName,
    };
  }
}
