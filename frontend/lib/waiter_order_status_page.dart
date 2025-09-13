import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

class WaiterOrderStatusPage extends StatefulWidget {
  final int orderId;
  const WaiterOrderStatusPage({super.key, required this.orderId});

  @override
  State<WaiterOrderStatusPage> createState() => _WaiterOrderStatusPageState();
}

class _WaiterOrderStatusPageState extends State<WaiterOrderStatusPage> {
  final ApiService _api = ApiService();
  String _status = 'Preparing';
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _poll();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final status = await _api.fetchOrderStatus(widget.orderId);
      if (mounted) {
        setState(() => _status = status);
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    final supabase = Supabase.instance.client;
    _channel = supabase
        .channel('order-${widget.orderId}')
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
            if (data == null) return;
            final newStatus = (data['status'] ?? '').toString();
            if (newStatus.isNotEmpty && mounted) {
              setState(() => _status = newStatus);
            }
          },
        )
        .subscribe();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return AppTheme.successColor;
      case 'Completed':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Preparing':
        return Icons.restaurant;
      case 'Ready':
        return Icons.check_circle;
      case 'Completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId} Status'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(_status), size: 64, color: _statusColor(_status)),
            const SizedBox(height: 12),
            Text(
              _status,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _statusColor(_status),
              ),
            ),
            const SizedBox(height: 24),
            const Text('This page updates automatically every 3 seconds'),
          ],
        ),
      ),
    );
  }
}
