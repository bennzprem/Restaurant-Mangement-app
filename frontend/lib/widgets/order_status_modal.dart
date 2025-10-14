import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OrderStatusModal extends StatefulWidget {
  final int orderId;
  final String customerName;
  final double totalAmount;
  final String deliveryAddress;

  const OrderStatusModal({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.totalAmount,
    required this.deliveryAddress,
  });

  @override
  State<OrderStatusModal> createState() => _OrderStatusModalState();
}

class _OrderStatusModalState extends State<OrderStatusModal>
    with TickerProviderStateMixin {
  String _currentStatus = 'Preparing';
  RealtimeChannel? _realtimeChannel;
  Timer? _pollingTimer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final Map<String, OrderStatusStep> _statusSteps = {
    'Preparing': OrderStatusStep(
      title: 'Preparing',
      subtitle: 'Your order is being prepared',
      icon: Icons.restaurant,
      color: Colors.orange,
      progress: 0.25,
    ),
    'Ready for pickup': OrderStatusStep(
      title: 'Ready for Pickup',
      subtitle: 'Your order is ready! Waiting for delivery person',
      icon: Icons.check_circle,
      color: Colors.blue,
      progress: 0.5,
    ),
    'Out for delivery': OrderStatusStep(
      title: 'Out for Delivery',
      subtitle: 'Your order is on the way!',
      icon: Icons.delivery_dining,
      color: Colors.purple,
      progress: 0.75,
    ),
    'Delivered': OrderStatusStep(
      title: 'Delivered',
      subtitle: 'Your order has been delivered!',
      icon: Icons.home,
      color: Colors.green,
      progress: 1.0,
    ),
  };

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _startRealtimeSubscription();
    _startPollingFallback();
    _fetchInitialStatus();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startRealtimeSubscription() {
    try {
      final supabase = Supabase.instance.client;
      _realtimeChannel = supabase
          .channel('order-status-${widget.orderId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: widget.orderId,
            ),
            callback: (payload) {
              final data = payload.newRecord as Map<String, dynamic>?;
              if (data != null) {
                final newStatus = data['status'] as String?;
                if (newStatus != null && newStatus != _currentStatus) {
                  _updateStatus(newStatus);
                }
              }
            },
          )
          .subscribe();
    } catch (e) {

    }
  }

  void _startPollingFallback() {
    // Fallback polling every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrderStatus();
    });
  }

  Future<void> _fetchInitialStatus() async {
    await _fetchOrderStatus();
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('id', widget.orderId)
          .maybeSingle();

      if (response != null) {
        final status = response['status'] as String?;
        if (status != null && status != _currentStatus) {
          _updateStatus(status);
        }
      }
    } catch (e) {

    }
  }

  void _updateStatus(String newStatus) {
    if (mounted) {
      setState(() {
        _currentStatus = newStatus;
      });

      // Animate progress bar
      final step = _statusSteps[newStatus];
      if (step != null) {
        _progressController.animateTo(step.progress);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep =
        _statusSteps[_currentStatus] ?? _statusSteps['Preparing']!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentStep.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentStep.icon,
                    color: currentStep.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.orderId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${widget.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress Bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _statusSteps.entries.map((entry) {
                        final isActive = _statusSteps.keys
                                .toList()
                                .indexOf(entry.key) <=
                            _statusSteps.keys.toList().indexOf(_currentStatus);
                        final isCurrent = entry.key == _currentStatus;

                        return Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? entry.value.color
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                                border: isCurrent
                                    ? Border.all(
                                        color: entry.value.color,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                entry.value.icon,
                                color:
                                    isActive ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.value.title,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? entry.value.color
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progressAnimation.value * currentStep.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(currentStep.color),
                      minHeight: 6,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Current Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentStep.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentStep.color.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    currentStep.icon,
                    color: currentStep.color,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStep.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: currentStep.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStep.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Address
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.deliveryAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStep.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderStatusStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;

  OrderStatusStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });
}
