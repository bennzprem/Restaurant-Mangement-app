import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api_service.dart';
import '../theme.dart';

class TableCountWidget extends StatefulWidget {
  const TableCountWidget({super.key});

  @override
  State<TableCountWidget> createState() => _TableCountWidgetState();
}

class _TableCountWidgetState extends State<TableCountWidget> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _tableCounts;
  bool _isLoading = true;
  String? _error;
  RealtimeChannel? _tableSessionsChannel;

  @override
  void initState() {
    super.initState();
    _loadTableCounts();
    _subscribeToTableSessions();
  }

  Future<void> _loadTableCounts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final counts = await _apiService.getTablesCount();

      setState(() {
        _tableCounts = counts;
        _isLoading = false;
      });
    } catch (e) {

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribeToTableSessions() {
    try {
      final client = Supabase.instance.client;
      _tableSessionsChannel = client
          .channel('public:table_sessions')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'table_sessions',
            callback: (payload) async {
              // Any change to table_sessions can affect occupancy; refresh counts
              await _loadTableCounts();
            },
          )
          .subscribe();
    } catch (_) {
      // Non-fatal: realtime not available
    }
  }

  @override
  void dispose() {
    _tableSessionsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Table Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            GestureDetector(
              onLongPress: () async {
                try {
                  final closed = await _apiService.closeAllTableSessions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Closed $closed active sessions.')),
                  );
                  await _loadTableCounts();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to close sessions: $e')),
                  );
                }
              },
              child: IconButton(
                onPressed: _loadTableCounts,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Table Count',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(height: 8),
                Text(
                  'Error loading table count: $_error',
                  style: TextStyle(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadTableCounts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_tableCounts != null)
          _buildTableCountCards()
        else
          const Center(child: Text('No data available')),
      ],
    );
  }

  Widget _buildTableCountCards() {
    final totalTables = _tableCounts!['total_tables'] ?? 0;
    final availableTables = _tableCounts!['available_tables'] ?? 0;
    final occupiedTables = _tableCounts!['occupied_tables'] ?? 0;

    return Column(
      children: [
        // Summary Card
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Restaurant Tables',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Tables: $totalTables',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Status Cards Row
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Available',
                availableTables,
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Occupied',
                occupiedTables,
                Colors.red,
                Icons.person,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Additional Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Table Status Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available tables are ready for new customers. Occupied tables have active dining sessions.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
